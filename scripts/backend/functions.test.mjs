import { test } from "node:test";
import assert from "node:assert/strict";
import {
  ApiError,
  EnrollmentService,
  hash,
} from "../../supabase/functions/_shared/service.ts";
import { enrollmentHandler } from "../../supabase/functions/_shared/handler.ts";
const id = "00000000-0000-4000-8000-000000000001";
test("browser preflight succeeds without authentication or backend access", async () => {
  const service = new EnrollmentService({
    researcher: async () => assert.fail("preflight must not authenticate"),
    rpc: async () => assert.fail("preflight must not access the database"),
  });
  const response = await enrollmentHandler(service)(
    new Request("https://example.invalid/collector", {
      method: "OPTIONS",
      headers: {
        origin: "https://dataapp-inky.vercel.app",
        "access-control-request-method": "POST",
        "access-control-request-headers": "authorization,apikey,content-type",
      },
    }),
  );
  assert.equal(response.status, 204);
  assert.equal(await response.text(), "");
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  assert.ok(
    response.headers.get("access-control-allow-methods").includes("POST"),
  );
  const allowed = response.headers
    .get("access-control-allow-headers")
    .split(/,\s*/);
  for (const header of ["authorization", "apikey", "content-type"])
    assert.ok(allowed.includes(header));
});
const device = {
  id,
  model: "test",
  manufacturer: "test",
  os: "test",
  os_version: "1",
  app_version: "1",
  created_at: new Date().toISOString(),
  sensors: [],
};

test("creation validates researcher and retries unique code collisions", async () => {
  let attempts = 0;
  const service = new EnrollmentService({
    researcher: async (bearer) => {
      assert.equal(bearer, "researcher-jwt");
      return id;
    },
    rpc: async (method, args) => {
      assert.equal(method, "create_participant_enrollment");
      assert.equal(args.code_digest.length, 64);
      assert.equal(args.token_digest.length, 64);
      if (++attempts === 1) throw new ApiError(409, "23505");
      return { id };
    },
  });
  const result = await service.create(
    {
      study_id: id,
      protocol_id: id,
      sex: "not_reported",
      dominant_hand: "right",
    },
    "researcher-jwt",
  );
  assert.equal(attempts, 2);
  assert.match(result.code, /^[A-Z2-9]{10}$/);
  assert.match(result.qr_payload, /^collector:\/\/enroll\?token=[a-f0-9]{64}$/);
});

test("enrollment accepts code and QR while issuing unique device credentials", async () => {
  const digests = [];
  const grants = [];
  const service = new EnrollmentService({
    researcher: async () => id,
    rpc: async (method, args) => {
      if (method === "consume_enrollment_attempt") return true;
      digests.push(args.credential_digest);
      grants.push(args.grant_digest);
      return { participant: { id } };
    },
  });
  const a = await service.enroll({ credential: "abcd234567", device });
  const b = await service.enroll({
    credential: `collector://enroll?token=${"a".repeat(64)}`,
    device: { ...device, id: "00000000-0000-4000-8000-000000000002" },
  });
  assert.equal(a.participant.id, b.participant.id);
  assert.notEqual(a.device_token, b.device_token);
  assert.equal(digests[0], await hash("ABCD234567"));
  assert.equal(digests[1], await hash("a".repeat(64)));
  assert.equal(grants[0], await hash(a.device_token));
});

test("shared throttle prevents enrollment and API does not disclose backend errors", async () => {
  let resolves = 0;
  const service = new EnrollmentService({
    researcher: async () => {
      throw new Error("private backend detail");
    },
    rpc: async (method) => {
      if (method === "resolve_enrollment") resolves++;
      return false;
    },
  });
  const handler = enrollmentHandler(service);
  const response = await handler(
    new Request("https://example.invalid", {
      method: "POST",
      body: JSON.stringify({
        action: "enroll",
        credential: "ABCD234567",
        device,
      }),
    }),
  );
  assert.equal(response.status, 429);
  assert.equal(resolves, 0);
  const denied = await handler(
    new Request("https://example.invalid", {
      method: "POST",
      body: JSON.stringify({ action: "create_participant" }),
    }),
  );
  assert(!(await denied.text()).includes("private backend detail"));
  const huge = await handler(
    new Request("https://example.invalid", {
      method: "POST",
      body: "x".repeat(33000),
    }),
  );
  assert.equal(huge.status, 413);
});

import { R2Storage } from "../../supabase/functions/_shared/r2.ts";
import { UploadService } from "../../supabase/functions/_shared/uploads.ts";
const key = `study/${id}/${id}/${id}/${id}/sensors.csv.gz`;
const r2Config = {
  endpoint: "https://testaccount.r2.cloudflarestorage.com",
  bucket: "test-bucket",
  accessKey: "test-access-key",
  secretKey: "test-secret-not-a-credential",
};

test("R2 URL signs object, expiry, length and overwrite protection without revealing secret", async () => {
  const r2 = new R2Storage(
    r2Config,
    fetch,
    () => new Date("2026-09-24T10:00:00Z"),
  );
  const signed = await r2.authorize({ object_key: key, size_bytes: 3 });
  const url = new URL(signed.url);
  assert.equal(url.pathname, `/test-bucket/${key}`);
  assert.equal(url.searchParams.get("X-Amz-Expires"), "600");
  assert.equal(
    url.searchParams.get("X-Amz-SignedHeaders"),
    "content-length;content-type;host;if-none-match",
  );
  assert.equal(signed.headers["if-none-match"], "*");
  assert.equal(signed.expires_at, "2026-09-24T10:10:00.000Z");
  assert(!signed.url.includes(r2Config.secretKey));
  assert.throws(() => r2.sign("PUT", "../other"), /invalid_object_key/);
});

test("R2 verification hashes received bytes, rejects corrupt or oversize objects", async () => {
  const manifest = {
    object_key: key,
    size_bytes: 3,
    sha256: await hash("abc"),
  };
  const r2 = new R2Storage(
    r2Config,
    async () =>
      new Response("abc", { headers: { "content-type": "application/gzip" } }),
  );
  await r2.verify(manifest);
  await assert.rejects(
    r2.verify({ ...manifest, sha256: "a".repeat(64) }),
    /checksum_mismatch/,
  );
  await assert.rejects(
    r2.verify({ ...manifest, size_bytes: 2 }),
    /size_mismatch/,
  );
});

test("failed remote verification never finalizes metadata and canonical server key is used", async () => {
  let finalized = false,
    authorizedKey;
  const manifest = {
    trial_id: id,
    object_key: key,
    size_bytes: 3,
    sha256: await hash("abc"),
    sync_status: "uploading",
  };
  const backend = {
    rpc: async (method, args) => {
      if (method === "finalize_trial_upload") {
        finalized = true;
        return { ...manifest, sync_status: "synced" };
      }
      return manifest;
    },
    researcher: async () => id,
  };
  const service = new UploadService(backend, () => ({
    authorize: async (file) => {
      authorizedKey = file.object_key;
      return {
        url: "https://example.invalid/upload",
        headers: {},
        expires_at: new Date().toISOString(),
      };
    },
    verify: async () => {
      throw new Error("corrupt");
    },
  }));
  await service.prepare(
    { session: {}, trial: {}, file: { object_key: "arbitrary/path" } },
    "a".repeat(64),
  );
  assert.equal(authorizedKey, key);
  await assert.rejects(
    service.finalize({ trial_id: id }, "a".repeat(64)),
    /corrupt/,
  );
  assert.equal(finalized, false);
});

test("raw export authorizes membership before signing the server key", async () => {
  const { ExportService } = await import(
    "../../supabase/functions/_shared/exports.ts"
  );
  let permitted = false,
    signed = 0;
  const key = `study/${id}/${id}/${id}/${id}/sensors.csv.gz`;
  const service = new ExportService(
    {
      researcher: async (bearer) => {
        assert.equal(bearer, "researcher");
        return id;
      },
      rpc: async (name, args) => {
        assert.equal(name, "researcher_trial_file");
        assert.deepEqual(args, { actor: id, trial_uuid: id });
        if (!permitted) throw new ApiError(403, "denied");
        return { object_key: key };
      },
    },
    () => ({
      download: async (value) => {
        assert.equal(value, key);
        signed++;
        return "https://example.test/signed";
      },
    }),
  );
  await assert.rejects(service.download({ trial_id: id }, "researcher"));
  assert.equal(signed, 0);
  permitted = true;
  const result = await service.download(
    { trial_id: id, object_key: "attacker-key" },
    "researcher",
  );
  assert.equal(signed, 1);
  assert.equal(result.expires_in_seconds, 900);
});
