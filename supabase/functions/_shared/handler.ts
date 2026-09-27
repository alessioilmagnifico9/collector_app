import { ExportService } from "./exports.ts";
import { UploadService } from "./uploads.ts";
import { ApiError, EnrollmentService, Json } from "./service.ts";
const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, apikey, content-type, x-client-info",
  "access-control-allow-methods": "POST, OPTIONS",
  "cache-control": "no-store",
};
export function enrollmentHandler(
  service: EnrollmentService,
  uploads?: UploadService,
  exports?: ExportService,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS")
      return new Response(null, { status: 204, headers });
    if (request.method !== "POST")
      return new Response(JSON.stringify({ error: "method_not_allowed" }), {
        status: 405,
        headers,
      });
    try {
      // Stream limit also applies to requests without a trustworthy Content-Length.
      const reader = request.body?.getReader();
      if (!reader) throw new ApiError(400, "invalid_request");
      let size = 0;
      const chunks: Uint8Array[] = [];
      while (true) {
        const part = await reader.read();
        if (part.done) break;
        size += part.value.length;
        if (size > 32768) {
          await reader.cancel();
          throw new ApiError(413, "request_too_large");
        }
        chunks.push(part.value);
      }
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) {
        bytes.set(chunk, offset);
        offset += chunk.length;
      }
      const body = JSON.parse(new TextDecoder().decode(bytes)) as Json;
      if (!body || Array.isArray(body) || typeof body !== "object")
        throw new ApiError(400, "invalid_request");
      const bearer =
        request.headers.get("authorization")?.replace(/^Bearer /, "") ?? "";
      let result: Json;
      switch (body.action) {
        case "download_trial":
          if (!exports) throw new ApiError(503, "export_unavailable");
          result = await exports.download(body, bearer);
          break;
        case "prepare_upload":
          if (!uploads) throw new ApiError(503, "upload_unavailable");
          result = await uploads.prepare(body, bearer);
          break;
        case "finalize_upload":
          if (!uploads) throw new ApiError(503, "upload_unavailable");
          result = await uploads.finalize(body, bearer);
          break;

        case "retrieve_enrollment":
          result = await service.retrieve(body, bearer);
          break;
        case "create_participant":
          result = await service.create(body, bearer);
          break;
        case "enroll":
          result = await service.enroll(body);
          break;
        case "refresh":
          result = await service.refresh(bearer);
          break;
        default:
          throw new ApiError(400, "unknown_action");
      }
      return new Response(JSON.stringify(result), { headers });
    } catch (error) {
      const status =
        error instanceof ApiError
          ? error.status
          : error instanceof SyntaxError
            ? 400
            : 503;
      // Never return raw database errors, participant codes, JWTs or request bodies.
      return new Response(
        JSON.stringify({
          error:
            status === 429
              ? "try_later"
              : status === 401 || status === 403
                ? "access_denied"
                : "request_failed",
        }),
        { status, headers },
      );
    }
  };
}
