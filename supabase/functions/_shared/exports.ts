import { Backend, Json, uuid } from "./service.ts";
import { RawStorage, UploadManifest } from "./r2.ts";

export class ExportService {
  constructor(
    private backend: Backend,
    private storage: () => RawStorage,
  ) {}
  async download(body: Json, bearer: string): Promise<Json> {
    const actor = await this.backend.researcher(bearer);
    const manifest = await this.backend.rpc<UploadManifest>(
      "researcher_trial_file",
      {
        actor,
        trial_uuid: uuid(body.trial_id),
      },
    );
    return {
      download_url: await this.storage().download(manifest.object_key),
      expires_in_seconds: 900,
    };
  }
}
