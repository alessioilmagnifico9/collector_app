import { ExportService } from "../_shared/exports.ts";
import { R2Storage } from "../_shared/r2.ts";
import { UploadService } from "../_shared/uploads.ts";
import { SupabaseBackend } from "../_shared/backend.ts";
import { EnrollmentService } from "../_shared/service.ts";
import { enrollmentHandler } from "../_shared/handler.ts";
const backend = new SupabaseBackend(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);
const storage = () =>
  new R2Storage({
    endpoint:
      Deno.env.get("R2_ENDPOINT") ||
      `https://${Deno.env.get("R2_ACCOUNT_ID") ?? ""}.r2.cloudflarestorage.com`,
    bucket: Deno.env.get("R2_BUCKET_NAME") ?? "",
    accessKey: Deno.env.get("R2_ACCESS_KEY_ID") ?? "",
    secretKey: Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "",
  });
Deno.serve(
  enrollmentHandler(
    new EnrollmentService(backend),
    new UploadService(backend, storage),
    new ExportService(backend, storage),
  ),
);
