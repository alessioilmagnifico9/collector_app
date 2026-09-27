import { createHash, createHmac } from "node:crypto";
import { ApiError } from "./service.ts";

export interface UploadManifest {
  id: string;
  trial_id: string;
  object_key: string;
  sha256: string;
  size_bytes: number;
  content_type: string;
  sync_status: string;
}
export interface RawStorage {
  authorize(manifest: UploadManifest): Promise<{
    url: string;
    headers: Record<string, string>;
    expires_at: string;
  }>;
  verify(manifest: UploadManifest): Promise<void>;
  download(key: string): Promise<string>;
}
export interface R2Config {
  endpoint: string;
  bucket: string;
  accessKey: string;
  secretKey: string;
}
const encode = (value: string) =>
  encodeURIComponent(value).replace(
    /[!'()*]/g,
    (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`,
  );
const digest = (value: string) =>
  createHash("sha256").update(value).digest("hex");
const hmac = (key: string | Uint8Array, value: string) =>
  createHmac("sha256", key).update(value).digest();

export class R2Storage implements RawStorage {
  constructor(
    private config: R2Config,
    private request: typeof fetch = fetch,
    private now: () => Date = () => new Date(),
  ) {
    const url = new URL(config.endpoint);
    if (
      url.protocol !== "https:" ||
      !/^[a-z0-9]+(?:\.(?:eu|fedramp))?\.r2\.cloudflarestorage\.com$/.test(
        url.hostname,
      ) ||
      url.pathname !== "/" ||
      url.search ||
      url.username ||
      url.password ||
      !/^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$/.test(config.bucket) ||
      !config.accessKey ||
      !config.secretKey
    )
      throw new Error("Invalid R2 server configuration");
  }
  sign(
    method: string,
    key: string,
    headers: Record<string, string> = {},
    seconds = 600,
  ): string {
    if (
      seconds < 1 ||
      seconds > 900 ||
      !/^study\/[0-9a-f-]{36}\/[0-9a-f-]{36}\/[0-9a-f-]{36}\/[0-9a-f-]{36}\/sensors\.csv\.gz$/.test(
        key,
      )
    )
      throw new ApiError(400, "invalid_object_key");
    const url = new URL(this.config.endpoint);
    url.pathname = `/${this.config.bucket}/${key}`;
    const date = this.now()
        .toISOString()
        .replace(/[:-]|\.\d{3}/g, ""),
      day = date.slice(0, 8);
    const scope = `${day}/auto/s3/aws4_request`;
    const signedHeaders = { host: url.host, ...headers };
    const names = Object.keys(signedHeaders).sort();
    const query: Record<string, string> = {
      "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
      "X-Amz-Credential": `${this.config.accessKey}/${scope}`,
      "X-Amz-Date": date,
      "X-Amz-Expires": String(seconds),
      "X-Amz-SignedHeaders": names.join(";"),
    };
    const canonicalQuery = Object.keys(query)
      .sort()
      .map((k) => `${encode(k)}=${encode(query[k])}`)
      .join("&");
    const canonicalHeaders = names
      .map(
        (k) =>
          `${k}:${signedHeaders[k as keyof typeof signedHeaders].trim().replace(/\s+/g, " ")}\n`,
      )
      .join("");
    const canonical = [
      method,
      url.pathname,
      canonicalQuery,
      canonicalHeaders,
      names.join(";"),
      "UNSIGNED-PAYLOAD",
    ].join("\n");
    const signingKey = hmac(
      hmac(hmac(hmac(`AWS4${this.config.secretKey}`, day), "auto"), "s3"),
      "aws4_request",
    );
    const signature = createHmac("sha256", signingKey)
      .update(`AWS4-HMAC-SHA256\n${date}\n${scope}\n${digest(canonical)}`)
      .digest("hex");
    url.search = `${canonicalQuery}&X-Amz-Signature=${signature}`;
    return url.toString();
  }
  async authorize(manifest: UploadManifest) {
    const headers = {
      "content-type": "application/gzip",
      "content-length": String(manifest.size_bytes),
      "if-none-match": "*",
    };
    return {
      url: this.sign("PUT", manifest.object_key, headers),
      headers,
      expires_at: new Date(this.now().getTime() + 600000).toISOString(),
    };
  }
  async download(key: string): Promise<string> {
    return this.sign("GET", key, {}, 900);
  }
  async verify(manifest: UploadManifest): Promise<void> {
    const response = await this.request(this.sign("GET", manifest.object_key), {
      signal: AbortSignal.timeout(120000),
      redirect: "error",
    });
    if (!response.ok || !response.body)
      throw new ApiError(503, "raw_file_unavailable");
    if (
      response.headers.get("content-type")?.split(";")[0] !== "application/gzip"
    ) {
      await response.body.cancel();
      throw new ApiError(409, "raw_file_type_mismatch");
    }
    const hash = createHash("sha256");
    let size = 0;
    const reader = response.body.getReader();
    try {
      while (true) {
        const part = await reader.read();
        if (part.done) break;
        size += part.value.length;
        if (size > manifest.size_bytes)
          throw new ApiError(409, "raw_file_size_mismatch");
        hash.update(part.value);
      }
    } finally {
      await reader.cancel();
    }
    if (size !== manifest.size_bytes || hash.digest("hex") !== manifest.sha256)
      throw new ApiError(409, "raw_file_checksum_mismatch");
  }
}
