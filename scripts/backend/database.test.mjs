import { PGlite } from "@electric-sql/pglite";
import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import { test } from "node:test";

const root = fileURLToPath(new URL("../../", import.meta.url));
const ids = {
  owner: "00000000-0000-4000-8000-000000000001",
  outsider: "00000000-0000-4000-8000-000000000002",
  viewer: "00000000-0000-4000-8000-000000000003",
};
async function database(before = null) {
  const db = new PGlite();
  // Minimal Supabase Auth contract, never a replacement for a live API test.
  await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    grant usage on schema auth, public to authenticated, anon, service_role;
    grant execute on function auth.uid() to authenticated, anon, service_role;
    insert into auth.users values ('${ids.owner}'), ('${ids.outsider}'), ('${ids.viewer}');`);
  for (const file of (await readdir(`${root}/supabase/migrations`))
    .filter((f) => f.endsWith(".sql"))
    .sort()) {
    if (before && file >= before) break;
    await db.exec(
      await readFile(`${root}/supabase/migrations/${file}`, "utf8"),
    );
  }
  return db;
}
async function asUser(db, id, action) {
  await db.exec(`set role authenticated; set request.jwt.claim.sub = '${id}';`);
  try {
    return await action();
  } finally {
    await db.exec("reset role; reset request.jwt.claim.sub;");
  }
}
async function createStudy(db, owner = ids.owner) {
  return asUser(
    db,
    owner,
    async () =>
      (await db.query("select public.create_study('Test study') as id")).rows[0]
        .id,
  );
}

test("fresh migrations enable RLS and deny anonymous access for every public table", async () => {
  const db = await database();
  try {
    const tables = (
      await db.query(
        "select tablename from pg_tables where schemaname='public'",
      )
    ).rows;
    assert(tables.length >= 11);
    for (const { tablename } of tables) {
      assert.equal(
        (
          await db.query(
            "select relrowsecurity from pg_class where oid=$1::regclass",
            [`public.${tablename}`],
          )
        ).rows[0].relrowsecurity,
        true,
      );
      await db.exec("set role anon");
      await assert.rejects(
        db.query(`select * from public.${tablename}`),
        /permission denied/,
      );
      await db.exec("reset role");
    }
    await db.exec("set role anon");
    await assert.rejects(
      db.query("select public.create_study('Unauthorized')"),
      /permission denied/,
    );
  } finally {
    await db.close();
  }
});

test("study creation is atomic and membership gates read/write independently of UI", async () => {
  const db = await database();
  try {
    const study = await createStudy(db);
    await db.query(
      "insert into public.study_members(study_id,researcher_id,role) values($1,$2,'viewer')",
      [study, ids.viewer],
    );
    await asUser(db, ids.owner, async () => {
      assert.equal(
        (await db.query("select * from public.studies")).rows.length,
        1,
      );
      await db.query("update public.studies set name='Renamed' where id=$1", [
        study,
      ]);
      await assert.rejects(
        db.query(
          "insert into public.study_members(study_id,researcher_id,role) values($1,$2,'owner')",
          [study, ids.outsider],
        ),
        /permission denied/,
      );
    });
    await asUser(db, ids.viewer, async () => {
      assert.equal(
        (await db.query("select * from public.studies")).rows.length,
        1,
      );
      assert.equal(
        (
          await db.query(
            "update public.studies set name='Invalid' returning id",
          )
        ).rows.length,
        0,
      );
      await assert.rejects(
        db.query(
          "insert into public.protocols(study_id,name) values($1,'Invalid')",
          [study],
        ),
        /row-level security/,
      );
    });
    await asUser(db, ids.outsider, async () => {
      assert.equal(
        (await db.query("select * from public.studies")).rows.length,
        0,
      );
      assert.equal(
        (await db.query("select * from public.study_members")).rows.length,
        0,
      );
      await assert.rejects(
        db.query(
          "insert into public.protocols(study_id,name) values($1,'Intrusion')",
          [study],
        ),
        /row-level security/,
      );
      await assert.rejects(
        db.query("select public.create_study('')"),
        /check constraint/,
      );
    });
    assert.equal(
      (await db.query("select * from public.studies")).rows.length,
      1,
    );
  } finally {
    await db.close();
  }
});

test("published versions reject mutations and active version cannot cross protocols", async () => {
  const db = await database();
  try {
    const study = await createStudy(db);
    const document = JSON.parse(
      await readFile(`${root}/protocols/example_protocol.json`, "utf8"),
    );
    await asUser(db, ids.owner, async () => {
      const protocol = (
        await db.query(
          "insert into public.protocols(study_id,name) values($1,'Protocol') returning id",
          [study],
        )
      ).rows[0].id;
      const other = (
        await db.query(
          "insert into public.protocols(study_id,name) values($1,'Other') returning id",
          [study],
        )
      ).rows[0].id;
      const version = (
        await db.query(
          "insert into public.protocol_versions(protocol_id,version,schema_version,document) values($1,1,1,$2) returning id",
          [protocol, document],
        )
      ).rows[0].id;
      await assert.rejects(
        db.query(
          "update public.protocols set active_version_id=$1 where id=$2",
          [version, protocol],
        ),
        /must be published/,
      );
      await db.query(
        "update public.protocol_versions set status='published',published_at=now() where id=$1",
        [version],
      );
      await db.query(
        "update public.protocols set active_version_id=$1 where id=$2",
        [version, protocol],
      );
      await assert.rejects(
        db.query(
          "update public.protocols set active_version_id=$1 where id=$2",
          [version, other],
        ),
        /must be published/,
      );
      await assert.rejects(
        db.query(
          "update public.protocol_versions set document='{}' where id=$1",
          [version],
        ),
        /immutable/,
      );
      await assert.rejects(
        db.query(
          "update public.protocol_versions set status='draft',published_at=null where id=$1",
          [version],
        ),
        /immutable/,
      );
    });
  } finally {
    await db.close();
  }
});

test("device visibility requires membership in an associated study", async () => {
  const db = await database();
  try {
    const study = await createStudy(db);
    const device = "00000000-0000-4000-8000-000000000020";
    await db.query(
      "insert into public.physical_devices values($1,'model','vendor','test','1','1','[]',now(),now())",
      [device],
    );
    await db.query(
      "insert into public.study_devices(study_id,physical_device_id) values($1,$2)",
      [study, device],
    );
    await asUser(db, ids.owner, async () =>
      assert.equal(
        (await db.query("select * from public.physical_devices")).rows.length,
        1,
      ),
    );
    await asUser(db, ids.outsider, async () =>
      assert.equal(
        (await db.query("select * from public.physical_devices")).rows.length,
        0,
      ),
    );
  } finally {
    await db.close();
  }
});

test("enrollment resolves one participant across phones and revocation invalidates grants", async () => {
  const db = await database();
  try {
    const study = await createStudy(db);
    const document = JSON.parse(
      await readFile(`${root}/protocols/example_protocol.json`, "utf8"),
    );
    const protocol = (
      await db.query(
        "insert into public.protocols(study_id,name) values($1,'Enrollment') returning id",
        [study],
      )
    ).rows[0].id;
    const version = (
      await db.query(
        "insert into public.protocol_versions(protocol_id,version,schema_version,status,published_at,document) values($1,1,1,'published',now(),$2) returning id",
        [protocol, document],
      )
    ).rows[0].id;
    await db.query(
      "update public.protocols set active_version_id=$1 where id=$2",
      [version, protocol],
    );
    const code = "a".repeat(64),
      token = "b".repeat(64),
      grantA = "c".repeat(64),
      grantB = "d".repeat(64);
    const params = [
      ids.owner,
      study,
      protocol,
      "not_reported",
      "right",
      code,
      token,
    ];
    const person = (
      await db.query(
        "select public.create_participant_enrollment($1,$2,$3,$4,$5,$6,$7) as result",
        params,
      )
    ).rows[0].result;
    await assert.rejects(
      db.query(
        "select public.create_participant_enrollment($1,$2,$3,$4,$5,$6,$7)",
        params,
      ),
      /unique constraint/,
    );
    assert.equal(
      (await db.query("select count(*)::int as n from public.participants"))
        .rows[0].n,
      1,
    );
    const device = {
      id: "00000000-0000-4000-8000-000000000021",
      model: "test",
      manufacturer: "test",
      os: "test",
      os_version: "1",
      app_version: "1",
      sensors: [],
      created_at: new Date().toISOString(),
    };
    const a = (
      await db.query("select public.resolve_enrollment($1,$2,$3) as result", [
        code,
        device,
        grantA,
      ])
    ).rows[0].result;
    const b = (
      await db.query("select public.resolve_enrollment($1,$2,$3) as result", [
        token,
        { ...device, id: "00000000-0000-4000-8000-000000000022" },
        grantB,
      ])
    ).rows[0].result;
    assert.equal(a.participant.id, person.id);
    assert.equal(b.participant.id, person.id);
    assert.equal(a.participant.display_number, 1);
    assert.equal(b.participant.display_number, a.participant.display_number);
    assert.equal(
      (
        await db.query("select public.authorize_participant($1) as result", [
          grantA,
        ])
      ).rows[0].result.physical_device_id,
      device.id,
    );
    await asUser(db, ids.owner, async () => {
      await assert.rejects(
        db.query("select * from public.enrollment_credentials"),
        /permission denied/,
      );
      await assert.rejects(
        db.query("select public.authorize_participant($1)", [grantA]),
        /permission denied/,
      );
    });
    await assert.rejects(
      db.query("select public.retrieve_participant_enrollment($1,$2,$3,$4)", [
        ids.outsider,
        person.id,
        "ABCD234567",
        "e".repeat(64),
      ]),
      /Study permission required/,
    );
    const recover = async (code) =>
      (
        await db.query(
          "select public.retrieve_participant_enrollment($1,$2,$3,$4) as result",
          [ids.owner, person.id, code, "e".repeat(64)],
        )
      ).rows[0].result;
    assert.equal((await recover("ABCD234567")).code, "ABCD234567");
    assert.equal((await recover("WXYZ234567")).code, "ABCD234567");
    assert.equal(
      (
        await db.query("select public.authorize_participant($1) as result", [
          grantA,
        ])
      ).rows[0].result.participant_id,
      person.id,
    );
    await db.query(
      "update public.enrollment_credentials set revoked_at=now() where participant_id=$1",
      [person.id],
    );
    assert.equal(
      (
        await db.query("select public.authorize_participant($1) as result", [
          grantA,
        ])
      ).rows[0].result,
      null,
    );
    await assert.rejects(
      db.query("select public.resolve_enrollment($1,$2,$3)", [
        code,
        device,
        "e".repeat(64),
      ]),
      /Enrollment unavailable/,
    );
    assert.equal(
      (
        await db.query(
          "select public.consume_enrollment_attempt('bucket',1) as ok",
        )
      ).rows[0].ok,
      true,
    );
    assert.equal(
      (
        await db.query(
          "select public.consume_enrollment_attempt('bucket',1) as ok",
        )
      ).rows[0].ok,
      false,
    );
  } finally {
    await db.close();
  }
});

test("draft publication validates nested content and rejects stale editor writes", async () => {
  const db = await database();
  try {
    const study = await createStudy(db);
    const document = JSON.parse(
      await readFile(`${root}/protocols/example_protocol.json`, "utf8"),
    );
    await asUser(db, ids.owner, async () => {
      const draft = (
        await db.query(
          "select public.create_protocol_draft($1,$2,$3) as result",
          [study, "Editable protocol", document],
        )
      ).rows[0].result;
      const invalid = structuredClone(document);
      invalid.sessions[0].tasks[0].repetitions = 0;
      await assert.rejects(
        db.query("select public.save_protocol_draft($1,$2,$3,true)", [
          draft.id,
          document,
          invalid,
        ]),
        /repetitions/,
      );
      const updated = structuredClone(document);
      updated.sessions[0].tasks[0].prompt = "Updated prompt";
      await db.query("select public.save_protocol_draft($1,$2,$3,false)", [
        draft.id,
        document,
        updated,
      ]);
      await assert.rejects(
        db.query("select public.save_protocol_draft($1,$2,$3,true)", [
          draft.id,
          document,
          document,
        ]),
        /another editor/,
      );
      await db.query("select public.save_protocol_draft($1,$2,$3,true)", [
        draft.id,
        updated,
        updated,
      ]);
      assert.equal(
        (
          await db.query(
            "select active_version_id from public.protocols where id=$1",
            [draft.protocol_id],
          )
        ).rows[0].active_version_id,
        draft.id,
      );
      const copy = (
        await db.query(
          "select public.create_protocol_draft($1,$2,$3,$4) as result",
          [study, "ignored", updated, draft.id],
        )
      ).rows[0].result;
      assert.notEqual(copy.id, draft.id);
      assert.equal(copy.version, 2);
      assert.equal(copy.status, "draft");
      for (const mutate of [
        (d) => (d.sessions[0].tasks[0].hand = "invalid"),
        (d) => d.sessions.push(d.sessions[0]),
        (d) => (d.sessions[0].tasks[0].duration_seconds = 900),
        (d) => (d.requested_hz = "100"),
        (d) => (d.sessions[0].tasks[0].extra = "hidden"),
      ]) {
        const bad = structuredClone(document);
        mutate(bad);
        await assert.rejects(
          db.query("select private.validate_protocol($1)", [bad]),
        );
      }
    });
    await asUser(
      db,
      ids.outsider,
      async () =>
        await assert.rejects(
          db.query("select public.create_protocol_draft($1,$2,$3)", [
            study,
            "Invalid",
            document,
          ]),
          /permission required/,
        ),
    );
  } finally {
    await db.close();
  }
});

async function uploadFixture(
  db,
  { singleTrial = false, startedAt = "2026-09-24T10:00:00Z" } = {},
) {
  const study = await createStudy(db);
  const document = JSON.parse(
    await readFile(`${root}/protocols/example_protocol.json`, "utf8"),
  );
  if (singleTrial)
    document.sessions[0].tasks = [
      {
        ...document.sessions[0].tasks[0],
        repetitions: 1,
        practice_repetitions: 0,
      },
    ];
  const protocol = (
    await db.query(
      "insert into public.protocols(study_id,name) values($1,'Upload') returning id",
      [study],
    )
  ).rows[0].id;
  const version = (
    await db.query(
      "insert into public.protocol_versions(protocol_id,version,schema_version,status,published_at,document) values($1,1,1,'published',now(),$2) returning id",
      [protocol, document],
    )
  ).rows[0].id;
  await db.query(
    "update public.protocols set active_version_id=$1 where id=$2",
    [version, protocol],
  );
  const participant = (
    await db.query(
      "select public.create_participant_enrollment($1,$2,$3,$4,$5,$6,$7) as result",
      [
        ids.owner,
        study,
        protocol,
        "not_reported",
        "right",
        "a".repeat(64),
        "b".repeat(64),
      ],
    )
  ).rows[0].result;
  const device = {
    id: "00000000-0000-4000-8000-000000000025",
    model: "test",
    manufacturer: "test",
    os: "test",
    os_version: "1",
    app_version: "1",
    sensors: [],
    created_at: "2026-09-24T10:00:00Z",
  };
  const grant = "c".repeat(64);
  await db.query("select public.resolve_enrollment($1,$2,$3)", [
    "a".repeat(64),
    device,
    grant,
  ]);
  const session = {
    id: "00000000-0000-4000-8000-000000000026",
    study_id: study,
    participant_id: participant.id,
    protocol_version_id: version,
    session_definition_id: document.sessions[0].id,
    started_at: startedAt,
    completed_at: null,
  };
  const task = document.sessions[0].tasks[0];
  const trial = {
    id: "00000000-0000-4000-8000-000000000027",
    study_id: study,
    participant_id: participant.id,
    session_id: session.id,
    task_id: task.id,
    prompt: task.prompt,
    repetition: 1,
    hand_used: "right",
    posture: task.posture,
    task_type: singleTrial ? task.task_type : "practice",
    device_role: task.device_role,
    physical_device_id: device.id,
    app_version: "1",
    protocol_version_id: version,
    schema_version: 1,
    quality: { duration_seconds: 1, sensors: [] },
    created_at: session.started_at,
  };
  const file = {
    id: "00000000-0000-4000-8000-000000000028",
    trial_id: trial.id,
    object_key: "arbitrary/client/key",
    size_bytes: 3,
    sha256: "d".repeat(64),
    content_type: "application/gzip",
    sync_status: "local",
    created_at: session.started_at,
    uploaded_at: null,
  };
  return { study, participant, session, trial, file, grant };
}

test("finalization locks its session before file mutation and survives phone clock skew", async () => {
  const db = await database();
  try {
    const f = await uploadFixture(db, {
      singleTrial: true,
      startedAt: "2099-01-01T00:00:00Z",
    });
    await db.query("select public.prepare_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.session,
      f.trial,
      f.file,
    ]);
    // Enforce the lock order at the write boundary. PGlite has one connection;
    // the real multi-connection race remains in the staging test plan.
    await db.exec(`create function public.assert_session_locked() returns trigger language plpgsql as $$
      begin
        if not exists(select 1 from pg_locks where (pid=pg_backend_pid() or (pg_backend_pid()=0 and pid is null))
          and relation='public.sessions'::regclass and mode='RowShareLock' and granted)
        then raise exception 'Session must be locked before finalizing a file'; end if;
        return new;
      end $$;
      create trigger assert_session_locked before update on public.trial_files
      for each row execute function public.assert_session_locked();`);
    await db.query("select public.finalize_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.trial.id,
      f.file.sha256,
      f.file.size_bytes,
    ]);
    const first = (
      await db.query(
        "select completed_at, started_at from public.sessions where id=$1",
        [f.session.id],
      )
    ).rows[0];
    assert(first.completed_at);
    assert(new Date(first.completed_at) >= new Date(first.started_at));
    await db.query("select public.finalize_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.trial.id,
      f.file.sha256,
      f.file.size_bytes,
    ]);
    assert.deepEqual(
      (
        await db.query(
          "select completed_at, started_at from public.sessions where id=$1",
          [f.session.id],
        )
      ).rows[0],
      first,
    );
  } finally {
    await db.close();
  }
});

test("upload metadata is scoped, idempotent and only verified finalization marks synced", async () => {
  const db = await database();
  try {
    const f = await uploadFixture(db);
    const prepare = async (trial = f.trial, file = f.file) =>
      (
        await db.query(
          "select public.prepare_trial_upload($1,$2,$3,$4) as result",
          [f.grant, f.session, trial, file],
        )
      ).rows[0].result;
    const first = await prepare(),
      second = await prepare();
    assert.deepEqual(first, second);
    await assert.rejects(
      prepare({ ...f.trial, id: ids.outsider }, { ...f.file, id: ids.viewer }),
      /repetition quota/,
    );
    await assert.rejects(
      prepare(
        {
          ...f.trial,
          id: ids.outsider,
          repetition: 2,
          task_type: "genuine",
          hand_used: "left",
        },
        { ...f.file, id: ids.viewer },
      ),
      /hand differs/,
    );

    assert.equal(
      first.object_key,
      `study/${f.study}/${f.participant.id}/${f.session.id}/${f.trial.id}/sensors.csv.gz`,
    );
    await assert.rejects(
      prepare({ ...f.trial, physical_device_id: ids.outsider }),
      /ownership mismatch/,
    );
    await assert.rejects(
      prepare({ ...f.trial, prompt: "Changed" }),
      /differs from pinned/,
    );
    await assert.rejects(
      prepare(f.trial, { ...f.file, sha256: "e".repeat(64) }),
      /identity conflict/,
    );
    await assert.rejects(
      db.query("select public.finalize_trial_upload($1,$2,$3,$4)", [
        f.grant,
        f.trial.id,
        "e".repeat(64),
        3,
      ]),
      /verification mismatch/,
    );
    assert.equal(
      (await db.query("select sync_status from public.trial_files")).rows[0]
        .sync_status,
      "uploading",
    );
    await db.query("select public.finalize_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.trial.id,
      f.file.sha256,
      3,
    ]);
    assert.equal((await prepare()).sync_status, "synced");
    const exported = (
      await db.query("select public.researcher_trial_file($1,$2) as result", [
        ids.owner,
        f.trial.id,
      ])
    ).rows[0].result;
    assert.equal(exported.object_key, first.object_key);
    await assert.rejects(
      db.query("select public.researcher_trial_file($1,$2)", [
        ids.outsider,
        f.trial.id,
      ]),
      /access required/,
    );
    await asUser(db, ids.outsider, async () =>
      assert.rejects(
        db.query("select public.researcher_trial_file($1,$2)", [
          ids.owner,
          f.trial.id,
        ]),
        /permission denied/,
      ),
    );

    assert.equal(
      (await db.query("select count(*)::int as n from public.trials")).rows[0]
        .n,
      1,
    );
    await asUser(
      db,
      ids.owner,
      async () =>
        await assert.rejects(
          db.query("select public.finalize_trial_upload($1,$2,$3,$4)", [
            f.grant,
            f.trial.id,
            f.file.sha256,
            3,
          ]),
          /permission denied/,
        ),
    );
  } finally {
    await db.close();
  }
});

test("dashboard snapshot respects tenant roles and excludes credentials", async () => {
  const db = await database();
  try {
    const f = await uploadFixture(db);
    await db.query("select public.prepare_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.session,
      f.trial,
      f.file,
    ]);
    await db.query("select public.fail_trial_upload($1,$2)", [
      f.grant,
      f.trial.id,
    ]);
    await db.query(
      "insert into public.study_members(study_id,researcher_id,role) values($1,$2,'viewer')",
      [f.study, ids.viewer],
    );
    for (const user of [ids.owner, ids.viewer])
      await asUser(db, user, async () => {
        const first = (
          await db.query("select public.study_dataset($1) as result", [f.study])
        ).rows[0].result;
        const second = (
          await db.query("select public.study_dataset($1) as result", [f.study])
        ).rows[0].result;
        assert.deepEqual(first, second);
        assert.equal(first.participants.length, 1);
        assert.equal(first.trials.length, 1);
        assert.equal(first.trial_files[0].sync_status, "failed");
        assert.equal(first.devices.length, 1);
        assert.equal(first.protocol_versions.length, 1);
        assert(!JSON.stringify(first).includes(f.grant));
        assert.deepEqual(
          Object.keys(first).sort(),
          [
            "export_schema_version",
            "study",
            "participants",
            "devices",
            "protocols",
            "protocol_versions",
            "sessions",
            "trials",
            "trial_files",
          ].sort(),
        );
      });
    await asUser(db, ids.outsider, async () =>
      assert.rejects(
        db.query("select public.study_dataset($1)", [f.study]),
        /permission required/,
      ),
    );
    await db.exec("set role anon");
    await assert.rejects(
      db.query("select public.study_dataset($1)", [f.study]),
      /permission denied/,
    );
    await db.exec("reset role");
    await db.query("select public.finalize_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.trial.id,
      f.file.sha256,
      3,
    ]);
    await db.query("select public.fail_trial_upload($1,$2)", [
      f.grant,
      f.trial.id,
    ]);
    assert.equal(
      (await db.query("select sync_status from public.trial_files")).rows[0]
        .sync_status,
      "synced",
    );
  } finally {
    await db.close();
  }
});

test("SQL export and raw gzip pass the independent offline dataset verifier", async () => {
  const { mkdtemp, mkdir, writeFile, rm } = await import("node:fs/promises");
  const { tmpdir } = await import("node:os");
  const { join, dirname } = await import("node:path");
  const { gzipSync } = await import("node:zlib");
  const { createHash } = await import("node:crypto");
  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  const directory = await mkdtemp(join(tmpdir(), "collector-export-"));
  const db = await database();
  try {
    const f = await uploadFixture(db);
    const raw = gzipSync(
      "timestamp_monotonic_ns,sensor_type,x,y,z,w,accuracy\n1000000000,accelerometer,1,2,3,,3\n1010000000,accelerometer,1,2,3,,3\n",
    );
    f.file.size_bytes = raw.length;
    f.file.sha256 = createHash("sha256").update(raw).digest("hex");
    f.trial.quality = {
      duration_seconds: 0.01,
      sensors: [
        {
          sensor_type: "accelerometer",
          sample_count: 2,
          duration_seconds: 0.01,
        },
      ],
      warnings: [],
    };
    const manifest = (
      await db.query(
        "select public.prepare_trial_upload($1,$2,$3,$4) as result",
        [f.grant, f.session, f.trial, f.file],
      )
    ).rows[0].result;
    await db.query("select public.finalize_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.trial.id,
      f.file.sha256,
      raw.length,
    ]);
    const snapshot = await asUser(
      db,
      ids.owner,
      async () =>
        (await db.query("select public.study_dataset($1) as result", [f.study]))
          .rows[0].result,
    );
    const filename = join(directory, manifest.object_key);
    await mkdir(dirname(filename), { recursive: true });
    await writeFile(filename, raw);
    await writeFile(join(directory, "metadata.json"), JSON.stringify(snapshot));
    const result = JSON.parse(
      (
        await promisify(execFile)(
          "python3",
          [
            join(root, "scripts/verify_dataset.py"),
            join(directory, "metadata.json"),
            directory,
          ],
          { encoding: "utf8" },
        )
      ).stdout,
    );
    assert.equal(result.verified_files, 1);
    assert.equal(result.pending_files, 0);
  } finally {
    await db.close();
    await rm(directory, { recursive: true, force: true });
  }
});

test("participant numbers are central, immutable, study scoped and never reused", async () => {
  const db = await database();
  try {
    const study = await createStudy(db);
    const other = await createStudy(db);
    const insert = (s) =>
      db.query(
        "insert into public.participants(study_id,sex,dominant_hand,display_number) values($1,'not_reported','right',999) returning id,display_number",
        [s],
      );
    const rows = await Promise.all(
      Array.from({ length: 20 }, () => insert(study)),
    );
    assert.deepEqual(
      rows.map((r) => r.rows[0].display_number).sort((a, b) => a - b),
      Array.from({ length: 20 }, (_, i) => i + 1),
    );
    assert.equal((await insert(other)).rows[0].display_number, 1);
    const first = rows[0].rows[0];
    await assert.rejects(
      db.query("update public.participants set display_number=90 where id=$1", [
        first.id,
      ]),
      /immutable/,
    );
    await assert.rejects(
      db.query("update public.participants set study_id=$1 where id=$2", [
        other,
        first.id,
      ]),
      /immutable/,
    );
    await db.query("delete from public.participants where study_id=$1", [
      study,
    ]);
    assert.equal((await insert(study)).rows[0].display_number, 21);
    await asUser(db, ids.owner, async () => {
      await assert.rejects(
        db.query("select * from private.participant_counters"),
        /permission denied/,
      );
    });
  } finally {
    await db.close();
  }
});

test("participant migration backfills tied timestamps deterministically without changing UUIDs", async () => {
  const db = await database("202609270001_participant_numbers.sql");
  try {
    const study = await createStudy(db);
    const other = await createStudy(db);
    const oldIds = [
      "10000000-0000-4000-8000-000000000003",
      "10000000-0000-4000-8000-000000000002",
      "10000000-0000-4000-8000-000000000001",
    ];
    for (const id of oldIds)
      await db.query(
        "insert into public.participants(id,study_id,sex,dominant_hand,created_at) values($1,$2,'not_reported','right','2026-01-01')",
        [id, study],
      );
    await db.query(
      "insert into public.participants(study_id,sex,dominant_hand) values($1,'not_reported','right')",
      [other],
    );
    await db.exec(
      await readFile(
        `${root}/supabase/migrations/202609270001_participant_numbers.sql`,
        "utf8",
      ),
    );
    const backfill = (
      await db.query(
        "select id,display_number from public.participants where study_id=$1 order by id",
        [study],
      )
    ).rows;
    assert.deepEqual(
      backfill.map((r) => r.id),
      oldIds.reverse(),
    );
    assert.deepEqual(
      backfill.map((r) => r.display_number),
      [1, 2, 3],
    );
    assert.equal(
      (
        await db.query(
          "insert into public.participants(study_id,sex,dominant_hand) values($1,'not_reported','right') returning display_number",
          [study],
        )
      ).rows[0].display_number,
      4,
    );
  } finally {
    await db.close();
  }
});

test("number backfill preserves existing enrollment grants and original R2 file manifests", async () => {
  const db = await database("202609270001_participant_numbers.sql");
  try {
    const f = await uploadFixture(db);
    await db.query("select public.prepare_trial_upload($1,$2,$3,$4)", [
      f.grant,
      f.session,
      f.trial,
      f.file,
    ]);
    const beforeFiles = (await db.query("select * from public.trial_files"))
      .rows;
    const beforeCredentials = (
      await db.query("select * from public.enrollment_credentials")
    ).rows;
    await db.exec(
      await readFile(
        `${root}/supabase/migrations/202609270001_participant_numbers.sql`,
        "utf8",
      ),
    );
    assert.deepEqual(
      (await db.query("select * from public.trial_files")).rows,
      beforeFiles,
    );
    assert.deepEqual(
      (await db.query("select * from public.enrollment_credentials")).rows,
      beforeCredentials,
    );
    assert.equal(
      (
        await db.query("select public.authorize_participant($1) as result", [
          f.grant,
        ])
      ).rows[0].result.participant_id,
      f.participant.id,
    );
    assert.equal(
      (
        await db.query(
          "select display_number from public.participants where id=$1",
          [f.participant.id],
        )
      ).rows[0].display_number,
      1,
    );
  } finally {
    await db.close();
  }
});
