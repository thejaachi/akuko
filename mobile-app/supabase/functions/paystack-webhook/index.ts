// paystack-webhook/index.ts
// Authoritative server-to-server endpoint for Paystack subscription lifecycle
// events. Verifies the HMAC-SHA512 signature against the RAW body, then patches
// the `subscriptions` table with the SERVICE ROLE (clients can never write it).
//
// Handled events:
//   charge.success          -> premium / active (+ period window)
//   subscription.create     -> store subscription_code + period window
//   subscription.disable    -> non-renewing or cancelled/free at period end
//   invoice.create          -> renewal charged -> extend period window
//   invoice.payment_failed  -> past_due
//
// IMPORTANT: this function MUST run with `verify_jwt = false` (Paystack does
// not send a Supabase JWT). Security comes from the signature check below.
//
// Secrets / env:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (auto-injected)
//   PAYSTACK_SECRET_KEY
//
// Deploy:  supabase functions deploy paystack-webhook --no-verify-jwt
// Paystack dashboard webhook URL:
//   https://<project-ref>.supabase.co/functions/v1/paystack-webhook

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import {
  verifyPaystackSignature,
  PAYSTACK_SECRET_KEY,
  paystackAmountToMajor,
  ledgerStatusFromTxn,
  upsertPaymentTransaction,
} from "../_shared/paystack.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Plain 200 — Paystack only needs a 2xx ack; no CORS (server-to-server).
function ack(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

interface PaystackEvent {
  event: string;
  data: Record<string, any>;
}

/** Resolve the local user_id for an event, preferring explicit metadata. */
async function resolveUserId(
  admin: SupabaseClient,
  data: Record<string, any>,
): Promise<string | null> {
  const metaUserId = data?.metadata?.user_id ??
    data?.subscription?.metadata?.user_id ?? null;
  if (metaUserId) return metaUserId as string;

  const customerCode = data?.customer?.customer_code ??
    data?.subscription?.customer?.customer_code ?? null;
  if (customerCode) {
    const { data: byCode } = await admin
      .from("subscriptions")
      .select("user_id")
      .eq("paystack_customer_code", customerCode)
      .maybeSingle();
    if (byCode?.user_id) return byCode.user_id as string;
  }

  // Last resort: resolve by billing email -> auth user -> profile.
  const email = data?.customer?.email ?? data?.subscription?.customer?.email;
  if (email) {
    const { data: list } = await admin.auth.admin.listUsers();
    const match = list?.users?.find(
      (u) => (u.email ?? "").toLowerCase() === String(email).toLowerCase(),
    );
    if (match) return match.id;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return ack({ error: "Method not allowed" }, 405);
  if (!PAYSTACK_SECRET_KEY) return ack({ error: "Not configured" }, 501);

  // Read the RAW body first — the signature is computed over these exact bytes.
  const raw = await req.text();
  const signature = req.headers.get("x-paystack-signature");
  const valid = await verifyPaystackSignature(raw, signature);
  if (!valid) return ack({ error: "Invalid signature" }, 401);

  let event: PaystackEvent;
  try {
    event = JSON.parse(raw);
  } catch {
    return ack({ error: "Invalid JSON" }, 400);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const data = event.data ?? {};
  const userId = await resolveUserId(admin, data);

  // Unknown user -> 200 ack so Paystack stops retrying; nothing we can do.
  if (!userId) return ack({ received: true, note: "user_unresolved" });

  const customerCode = data?.customer?.customer_code ??
    data?.subscription?.customer?.customer_code ?? null;
  const subscriptionCode = data?.subscription_code ??
    data?.subscription?.subscription_code ?? data?.plan?.subscription_code ??
    null;

  // Compute a period window where the payload provides one.
  const periodStart = data?.paid_at ?? data?.createdAt ?? null;
  const periodEnd = data?.next_payment_date ??
    data?.subscription?.next_payment_date ?? null;

  const patch: Record<string, unknown> = { user_id: userId };
  if (customerCode) patch.paystack_customer_code = customerCode;
  if (subscriptionCode) patch.paystack_subscription_code = subscriptionCode;

  switch (event.event) {
    case "charge.success":
    case "subscription.create":
    case "invoice.create": {
      patch.plan = "premium";
      patch.status = "active";
      if (periodStart) patch.current_period_start = periodStart;
      if (periodEnd) patch.current_period_end = periodEnd;
      break;
    }
    case "invoice.payment_failed": {
      patch.status = "past_due";
      break;
    }
    case "subscription.disable": {
      // Subscription cancelled. The user keeps premium until the paid period
      // ends; mark non-renewing if a future end is known, else downgrade.
      if (periodEnd && new Date(periodEnd) > new Date()) {
        patch.status = "non-renewing";
        patch.current_period_end = periodEnd;
      } else {
        patch.plan = "free";
        patch.status = "cancelled";
      }
      break;
    }
    default:
      return ack({ received: true, ignored: event.event });
  }

  const { error } = await admin
    .from("subscriptions")
    .upsert(patch, { onConflict: "user_id" });

  if (error) return ack({ error: error.message }, 500);

  const reference = (data?.reference ?? data?.invoice_code ?? data?.id) as
    | string
    | undefined;
  const ledgerEvents = new Set([
    "charge.success",
    "subscription.create",
    "invoice.create",
    "invoice.payment_failed",
  ]);
  if (reference && ledgerEvents.has(event.event)) {
    const ledgerStatus =
      event.event === "invoice.payment_failed"
        ? "failed"
        : ledgerStatusFromTxn(data?.status ?? "success");
    const ledgerErr = await upsertPaymentTransaction(admin, {
      user_id: userId,
      reference: String(reference),
      amount: paystackAmountToMajor(data?.amount ?? data?.paid_amount),
      currency: (data?.currency as string) ?? "NGN",
      status: ledgerStatus,
      paystack_event: event.event,
      metadata: { paystack: data },
    });
    if (ledgerErr) return ack({ error: ledgerErr }, 500);
  }

  return ack({ received: true, event: event.event });
});
