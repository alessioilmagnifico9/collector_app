import { ApiError, Backend, Json } from "./service.ts";
export class SupabaseBackend implements Backend {
  constructor(
    private url: string,
    private serviceKey: string,
  ) {
    if (!url || !serviceKey) throw new Error("Missing server configuration");
  }
  async rpc<T>(name: string, params: Json): Promise<T> {
    const response = await fetch(`${this.url}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: {
        apikey: this.serviceKey,
        authorization: `Bearer ${this.serviceKey}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(params),
      signal: AbortSignal.timeout(30000),
    });
    const body = await response.json();
    if (!response.ok)
      throw new ApiError(
        response.status === 401 || response.status === 403 ? 403 : 400,
        typeof body.code === "string" ? body.code : "backend_failed",
      );
    return body as T;
  }
  async researcher(bearer: string): Promise<string> {
    if (!bearer) throw new ApiError(401, "authentication_required");
    const response = await fetch(`${this.url}/auth/v1/user`, {
      headers: { apikey: this.serviceKey, authorization: `Bearer ${bearer}` },
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new ApiError(401, "authentication_required");
    const user = await response.json();
    if (!user.id || user.is_anonymous === true)
      throw new ApiError(403, "researcher_required");
    return user.id;
  }
}
