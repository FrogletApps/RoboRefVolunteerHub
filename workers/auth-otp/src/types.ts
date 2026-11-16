export interface EmailRecipient {
  email: string;
  name: string;
}

export interface OutboundEmailPayload {
  to: string | EmailRecipient | Array<string | EmailRecipient>;
  from: string | EmailRecipient;
  subject: string;
  text?: string;
  html?: string;
}

export interface SendEmailBinding {
  send(message: OutboundEmailPayload): Promise<{ messageId?: string } | void>;
}

export interface KvStore {
  get(key: string): Promise<string | null>;
  put(
    key: string,
    value: string,
    options?: { expirationTtl?: number }
  ): Promise<void>;
  delete(key: string): Promise<void>;
}

export interface Env {
  EMAIL: SendEmailBinding;
  AUTH_OTP_KV: KvStore;

  // Encrypted Secrets (configured via `wrangler secret put ...`)
  INVITE_CODES: string;
  OTP_HMAC_SECRET: string;
  FIREBASE_SERVICE_ACCOUNT_JSON: string;
  TURNSTILE_SECRET_KEY?: string;

  // Plaintext Environment Variables (`wrangler.jsonc` vars)
  SENDER_EMAIL?: string;
  SENDER_NAME?: string;
  MAX_DAILY_EMAILS_PER_USER?: string;
  MAX_HOURLY_EMAILS_PER_IP?: string;
  MAX_MINUTE_EMAILS_PER_IP?: string;
  MAX_DAILY_EMAILS_GLOBAL?: string;
  OTP_COOLDOWN_SECONDS?: string;
  OTP_TTL_SECONDS?: string;
  MAX_OTP_ATTEMPTS?: string;
  REQUIRE_TURNSTILE?: string;
  ALLOWED_ORIGINS?: string;
}

export interface StoredOtpRecord {
  codeHash: string;
  attempts: number;
  createdAtMs: number;
}

export type AuthMode = "login" | "join";

export interface RequestOtpBody {
  mode: AuthMode;
  email: string;
  inviteCode?: string;
  turnstileToken?: string;
}

export interface VerifyOtpBody {
  email: string;
  code: string;
}

export interface ClaimInviteBody {
  idToken?: string;
  inviteCode: string;
  turnstileToken?: string;
}

export class HttpError extends Error {
  public readonly status: number;
  public readonly code: string;
  public readonly retryAfterSeconds?: number;

  constructor(
    status: number,
    code: string,
    message: string,
    retryAfterSeconds?: number
  ) {
    super(message);
    this.status = status;
    this.code = code;
    this.retryAfterSeconds = retryAfterSeconds;
  }
}
