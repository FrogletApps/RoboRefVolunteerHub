const encoder = new TextEncoder();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

/**
 * Normalizes and validates an email address.
 * Returns null if invalid or suspiciously long (> 254 chars per RFC 5321).
 */
export function normalizeAndValidateEmail(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const normalized = raw.trim().toLowerCase();
  if (normalized.length < 5 || normalized.length > 254) return null;
  if (!EMAIL_REGEX.test(normalized)) return null;
  return normalized;
}

/**
 * Computes HMAC-SHA256 hex digest using Web Crypto API.
 */
export async function hmacSha256Hex(
  secret: string,
  message: string
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sigBuffer = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(message)
  );
  return bytesToHex(new Uint8Array(sigBuffer));
}

/**
 * Constant-time string comparison that hashes both inputs with an ephemeral
 * random HMAC key first so neither content nor string length leaks via timing.
 */
export async function timingSafeEqualStrings(
  a: string,
  b: string
): Promise<boolean> {
  const ephemeralSecret = crypto.getRandomValues(new Uint8Array(32));
  const key = await crypto.subtle.importKey(
    "raw",
    ephemeralSecret,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const [macA, macB] = await Promise.all([
    crypto.subtle.sign("HMAC", key, encoder.encode(a)),
    crypto.subtle.sign("HMAC", key, encoder.encode(b)),
  ]);

  const bytesA = new Uint8Array(macA);
  const bytesB = new Uint8Array(macB);
  let diff = bytesA.length ^ bytesB.length;
  const len = Math.min(bytesA.length, bytesB.length);
  for (let i = 0; i < len; i++) {
    diff |= bytesA[i] ^ bytesB[i];
  }
  return diff === 0;
}

/**
 * Verifies a submitted invite code against a comma-separated list of valid codes
 * in `INVITE_CODES` without short-circuiting.
 */
export async function verifyInviteCodeConstantTime(
  submittedRaw: unknown,
  configuredCodesCsv: string | undefined
): Promise<boolean> {
  if (typeof submittedRaw !== "string" || !configuredCodesCsv) {
    return false;
  }
  const candidate = submittedRaw.trim().toUpperCase();
  if (!candidate || candidate.length > 64) {
    return false;
  }

  const validCodes = configuredCodesCsv
    .split(",")
    .map((c) => c.trim().toUpperCase())
    .filter((c) => c.length > 0);

  if (validCodes.length === 0) {
    return false;
  }

  let matched = false;
  for (const valid of validCodes) {
    const isMatch = await timingSafeEqualStrings(candidate, valid);
    if (isMatch) {
      matched = true;
    }
  }
  return matched;
}

/**
 * Generates an unbiased 6-digit numeric OTP ("000000" to "999999") using
 * CSPRNG rejection sampling.
 */
export function generateSixDigitOtp(): string {
  const maxUnbiased = 4_294_000_000; // Largest multiple of 1,000,000 < 2^32
  const buf = new Uint32Array(1);
  while (true) {
    crypto.getRandomValues(buf);
    const val = buf[0];
    if (val < maxUnbiased) {
      return (val % 1_000_000).toString().padStart(6, "0");
    }
  }
}

export function bytesToHex(bytes: Uint8Array): string {
  let out = "";
  for (let i = 0; i < bytes.length; i++) {
    out += bytes[i].toString(16).padStart(2, "0");
  }
  return out;
}
