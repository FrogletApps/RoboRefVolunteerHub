import type { Env } from "./types.ts";
import { HttpError } from "./types.ts";

interface TurnstileVerifyResponse {
  success: boolean;
  "error-codes"?: string[];
}

export async function verifyTurnstileToken(
  env: Env,
  token: string | undefined,
  remoteIp: string | null,
  fetchImpl: typeof fetch = fetch
): Promise<void> {
  const requireTurnstile =
    (env.REQUIRE_TURNSTILE ?? "true").trim().toLowerCase() !== "false";

  if (!requireTurnstile) {
    return;
  }

  const secret = env.TURNSTILE_SECRET_KEY?.trim();
  if (!secret) {
    throw new HttpError(
      500,
      "turnstile_misconfigured",
      "Bot protection is enabled on the server, but TURNSTILE_SECRET_KEY is not configured."
    );
  }

  if (!token || !token.trim()) {
    throw new HttpError(
      400,
      "turnstile_required",
      "Please complete the security check before requesting a verification code."
    );
  }

  const formData = new URLSearchParams();
  formData.set("secret", secret);
  formData.set("response", token.trim());
  if (remoteIp) {
    formData.set("remoteip", remoteIp);
  }

  const resp = await fetchImpl(
    "https://challenges.cloudflare.com/turnstile/v0/siteverify",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: formData.toString(),
    }
  );

  if (!resp.ok) {
    throw new HttpError(
      502,
      "turnstile_upstream_error",
      "Unable to verify security check right now. Please try again."
    );
  }

  const result = (await resp.json()) as TurnstileVerifyResponse;
  if (!result.success) {
    throw new HttpError(
      403,
      "turnstile_failed",
      "Security check failed or expired. Please refresh and try again."
    );
  }
}
