import { Backend, Json, ApiError, hash, uuid } from "./service.ts";
import { RawStorage, UploadManifest } from "./r2.ts";
export class UploadService {
  constructor(
    private backend: Backend,
    private storage: () => RawStorage,
  ) {}
  async prepare(body: Json, bearer: string): Promise<Json> {
    if (!/^[a-f0-9]{64}$/.test(bearer))
      throw new ApiError(401, "enrollment_required");
    if (!body.session || !body.trial || !body.file)
      throw new ApiError(400, "invalid_trial");
    const manifest = await this.backend.rpc<UploadManifest>(
      "prepare_trial_upload",
      {
        grant_digest: await hash(bearer),
        session_data: body.session,
        trial_data: body.trial,
        file_data: body.file,
      },
    );
    if (manifest.sync_status === "synced")
      return { manifest, upload_required: false };
    return {
      manifest,
      upload_required: true,
      ...(await this.storage().authorize(manifest)),
    };
  }
  async finalize(body: Json, bearer: string): Promise<Json> {
    if (!/^[a-f0-9]{64}$/.test(bearer))
      throw new ApiError(401, "enrollment_required");
    const params = {
      grant_digest: await hash(bearer),
      trial_uuid: uuid(body.trial_id),
    };
    const manifest = await this.backend.rpc<UploadManifest>(
      "trial_upload_manifest",
      params,
    );
    try {
      await this.storage().verify(manifest);
    } catch (error) {
      await this.backend.rpc("fail_trial_upload", params).catch(() => {});
      throw error;
    }
    const verified = await this.backend.rpc<Json>("finalize_trial_upload", {
      ...params,
      verified_sha256: manifest.sha256,
      verified_size: manifest.size_bytes,
    });
    return { manifest: verified, verified: true };
  }
}
