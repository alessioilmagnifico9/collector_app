export type Json = Record<string, unknown>;
export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
  ) {
    super(code);
  }
}
export interface Backend {
  rpc<T>(name: string, params: Json): Promise<T>;
  researcher(bearer: string): Promise<string>;
}
export function text(value: unknown, name: string, max = 200): string {
  if (typeof value !== "string" || value.length < 1 || value.length > max)
    throw new ApiError(400, `invalid_${name}`);
  return value;
}
export function uuid(value: unknown): string {
  const id = text(value, "id", 36);
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(
      id,
    )
  )
    throw new ApiError(400, "invalid_id");
  return id;
}
export async function hash(value: string): Promise<string> {
  return [
    ...new Uint8Array(
      await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)),
    ),
  ]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
export function randomToken(length = 32): string {
  return [...crypto.getRandomValues(new Uint8Array(length))]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
export function participantCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  // 32 symbols, rejection sampling avoids modulo bias if alphabet changes.
  let result = "";
  while (result.length < 10) {
    const byte = crypto.getRandomValues(new Uint8Array(1))[0];
    if (byte < 256 - (256 % alphabet.length))
      result += alphabet[byte % alphabet.length];
  }
  return result;
}
function choice(value: unknown, values: string[]): string {
  if (typeof value !== "string" || !values.includes(value))
    throw new ApiError(400, "invalid_choice");
  return value;
}
export class EnrollmentService {
  constructor(private backend: Backend) {}
  async create(body: Json, bearer: string): Promise<Json> {
    const researcher = await this.backend.researcher(bearer);
    const study = uuid(body.study_id),
      protocol = uuid(body.protocol_id);
    const sex = choice(body.sex, [
      "female",
      "male",
      "intersex",
      "not_reported",
    ]);
    const hand = choice(body.dominant_hand, ["left", "right", "either"]);
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = participantCode(),
        token = randomToken();
      try {
        const participant = await this.backend.rpc<Json>(
          "create_participant_enrollment",
          {
            researcher_uuid: researcher,
            study_uuid: study,
            protocol_uuid: protocol,
            participant_sex: sex,
            participant_hand: hand,
            enrollment_code: code,
            code_digest: await hash(code),
            token_digest: await hash(token),
          },
        );
        return {
          participant,
          code,
          qr_payload: `collector://enroll?token=${token}`,
        };
      } catch (error) {
        if (!(error instanceof ApiError) || error.code !== "23505") throw error;
      }
    }
    throw new ApiError(503, "enrollment_busy");
  }
  async retrieve(body: Json, bearer: string): Promise<Json> {
    const researcher = await this.backend.researcher(bearer);
    const person = uuid(body.participant_id);
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = participantCode();
      try {
        const result = await this.backend.rpc<Json>(
          "retrieve_participant_enrollment",
          {
            researcher_uuid: researcher,
            person_uuid: person,
            replacement_code: code,
            replacement_digest: await hash(code),
          },
        );
        return {
          ...result,
          qr_payload: `collector://enroll?token=${result.code}`,
        };
      } catch (error) {
        if (!(error instanceof ApiError) || error.code !== "23505") throw error;
      }
    }
    throw new ApiError(503, "enrollment_busy");
  }
  async enroll(body: Json): Promise<Json> {
    // Atomic shared limiter prevents bypass by changing devices, tokens or IP headers.
    if (
      !(await this.backend.rpc<boolean>("consume_enrollment_attempt", {
        subject_hash: "enrollment_global",
        max_attempts: 300,
      }))
    )
      throw new ApiError(429, "try_later");
    let input = text(body.credential, "credential", 200).trim();
    if (input.startsWith("collector://")) {
      const uri = new URL(input);
      if (uri.hostname !== "enroll")
        throw new ApiError(400, "invalid_credential");
      input = uri.searchParams.get("token") ?? "";
    } else if (!/^[0-9a-f]{64}$/.test(input)) {
      input = input.toUpperCase();
    }
    if (!/^[A-Z2-9]{10}$/.test(input) && !/^[0-9a-f]{64}$/.test(input))
      throw new ApiError(401, "enrollment_unavailable");
    const digest = await hash(input);
    // Bounded number of rows: throttle using 256 hash-prefix buckets.
    if (
      !(await this.backend.rpc<boolean>("consume_enrollment_attempt", {
        subject_hash: `code_${digest.slice(0, 2)}`,
        max_attempts: 20,
      }))
    )
      throw new ApiError(429, "try_later");
    const device = body.device as Json | undefined;
    if (!device || typeof device !== "object")
      throw new ApiError(400, "invalid_device");
    uuid(device.id);
    for (const key of [
      "model",
      "manufacturer",
      "os",
      "os_version",
      "app_version",
      "created_at",
    ])
      text(device[key], key);
    if (!Array.isArray(device.sensors) || device.sensors.length > 16)
      throw new ApiError(400, "invalid_sensors");
    const token = randomToken();
    const context = await this.backend.rpc<Json>("resolve_enrollment", {
      credential_digest: digest,
      device,
      grant_digest: await hash(token),
    });
    return { ...context, device_token: token };
  }
  async refresh(bearer: string): Promise<Json> {
    const grant = await this.backend.rpc<Json | null>("authorize_participant", {
      grant_digest: await hash(bearer),
    });
    if (!grant) throw new ApiError(401, "enrollment_required");
    const context = await this.backend.rpc<Json | null>("enrollment_context", {
      person_uuid: grant.participant_id,
    });
    if (!context) throw new ApiError(401, "enrollment_required");
    return context;
  }
}
