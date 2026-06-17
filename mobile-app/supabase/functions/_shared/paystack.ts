// _shared/paystack.ts
// Shared Paystack helpers for the Akuko edge functions.
//
//   * paystackFetch()            -> authenticated server-side call to the
//                                   Paystack REST API using PAYSTACK_SECRET_KEY.
//   * verifyPaystackSignature()  -> HMAC-SHA512 webhook signature verification
//                                   (constant-time compare).
//   * mapPaystackStatus()        -> Paystack subscription status -> our enum.
//
// The secret key NEVER leaves the server. Set it with:
//   supabase secrets set PAYSTACK_SECRET_KEY=sk_live_xxx

import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

const PAYSTACK_BASE = "https://api.paystack.co";

export const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY") ?? "";

export interface PaystackResult<T = unknown> {
  ok: boolean;
  httpStatus: number;
  status: boolean; // Paystack envelope `status`
  message: string;
  data: T;
}

/** Authenticated call to the Paystack REST API (server-side, secret key). */
export async function paystackFetch<T = unknown>(
  path: string,
  init: RequestInit = {},
): Promise<PaystackResult<T>> {
  const res = await fetch(`${PAYSTACK_BASE}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  });

  let json: Record<string, unknown> = {};
  try {
    json = await res.json();
  } catch {
    // Non-JSON / empty body.
  }

  return {
    ok: res.ok,
    httpStatus: res.status,
    status: json.status === true,
    message: typeof json.message === "string" ? json.message : "",
    data: (json.data ?? {}) as T,
  };
}

const encoder = new TextEncoder();

function toHex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Length-safe constant-time string comparison. */
function timingSafeEqual(a: string, b: string): boolean {
  // Compare against a fixed length to avoid leaking which string is longer.
  const len = Math.max(a.length, b.length);
  let mismatch = a.length === b.length ? 0 : 1;
  for (let i = 0; i < len; i++) {
    const ca = a.charCodeAt(i) || 0;
    const cb = b.charCodeAt(i) || 0;
    mismatch |= ca ^ cb;
  }
  return mismatch === 0;
}

/**
 * Verifies a Paystack webhook signature: HMAC-SHA512 of the RAW request body
 * keyed by PAYSTACK_SECRET_KEY, hex-encoded, constant-time compared to the
 * `x-paystack-signature` header. Always pass the raw (unparsed) body string.
 */
export async function verifyPaystackSignature(
  rawBody: string,
  signature: string | null,
): Promise<boolean> {
  if (!signature || !PAYSTACK_SECRET_KEY) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(PAYSTACK_SECRET_KEY),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, encoder.encode(rawBody));
  return timingSafeEqual(toHex(mac), signature.trim());
}

export type LedgerStatus =
  | "pending"
  | "success"
  | "failed"
  | "abandoned"
  | "reversed";

export interface LedgerInput {
  user_id: string;
  reference: string;
  amount: number;
  currency?: string;
  status: LedgerStatus;
  paystack_event?: string;
  metadata?: Record<string, unknown>;
}

/** Paystack amounts are minor units (kobo); `payment_transactions.amount` is major. */
export function paystackAmountToMajor(amount: number | undefined | null): number {
  if (amount == null || !Number.isFinite(amount)) return 0;
  return Math.round(amount) / 100;
}

export function ledgerStatusFromTxn(status: string | undefined): LedgerStatus {
  switch ((status ?? "").toLowerCase()) {
    case "success":
      return "success";
    case "failed":
      return "failed";
    case "abandoned":
      return "abandoned";
    case "reversed":
      return "reversed";
    default:
      return "pending";
  }
}

/**
 * Idempotent ledger write (unique on `reference`). Service role only.
 */
export async function upsertPaymentTransaction(
  admin: SupabaseClient,
  input: LedgerInput,
): Promise<string | null> {
  const { error } = await admin.from("payment_transactions").upsert(
    {
      user_id: input.user_id,
      reference: input.reference,
      amount: input.amount,
      currency: input.currency ?? "NGN",
      status: input.status,
      paystack_event: input.paystack_event ?? null,
      metadata: input.metadata ?? {},
    },
    { onConflict: "reference" },
  );
  return error?.message ?? null;
}

/** Maps a Paystack subscription/charge status to our `subscriptions.status`. */
export function mapPaystackStatus(raw: string | undefined | null): string {
  switch ((raw ?? "").toLowerCase()) {
    case "active":
    case "success":
      return "active";
    case "non-renewing":
      return "non-renewing";
    case "attention":
      return "attention";
    case "completed":
      return "completed";
    case "cancelled":
    case "canceled":
      return "cancelled";
    case "past_due":
      return "past_due";
    default:
      return "incomplete";
  }
}
