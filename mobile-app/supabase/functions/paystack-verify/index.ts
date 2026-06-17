// paystack-verify/index.ts
// Verifies a Paystack transaction server-side after the client returns from the
// hosted checkout. On a successful charge it upserts the caller's
// `subscriptions` row to premium (service role). The webhook remains the
// authoritative source for recurring billing; this gives the client an
// immediate, trustworthy confirmation right after checkout.
//
// Request  (POST, JSON):  { "reference": "<paystack-reference>" }
// Response (200, JSON):
//   { "status": "success" | "failed" | "pending", "plan": "premium" | "free" }
// Auth: requires the caller's Supabase JWT (verify_jwt = true).
//
// Secrets / env:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (auto-injected)
//   PAYSTACK_SECRET_KEY
//
// Deploy:  supabase functions deploy paystack-verify

import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import {
  paystackFetch,
  PAYSTACK_SECRET_KEY,
  paystackAmountToMajor,
  ledgerStatusFromTxn,
  upsertPaymentTransaction,
} from "../_shared/paystack.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/** 50 cowries per ₦1,000 NGN — must match WalletConstants in the Flutter app. */
const COWRIES_PER_THOUSAND_NGN = 50;

function ngnToCowries(amountNgn: number): number {
  return Math.floor((amountNgn / 1000) * COWRIES_PER_THOUSAND_NGN);
}

interface PaystackTxn {
  status: string;
  reference?: string;
  amount?: number;
  currency?: string;
  paid_at?: string;
  customer?: { customer_code?: string; email?: string };
  metadata?: {
    user_id?: string;
    type?: string;
    cowries?: number | string;
  } | null;
  plan?: string | { plan_code?: string } | null;
}

Deno.serve(async (req) => {
  const pre = handleCors(req);
  if (pre) return pre;
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  if (!PAYSTACK_SECRET_KEY) {
    return errorResponse("Payments not configured (PAYSTACK_SECRET_KEY)", 501);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return errorResponse("Missing bearer token", 401);
  }

  let body: { reference?: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }
  const reference = body.reference;
  if (!reference) return errorResponse("reference is required", 400);

  // Authoritative caller identity.
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return errorResponse("Unauthorized", 401);
  const userId = userData.user.id;

  const result = await paystackFetch<PaystackTxn>(
    `/transaction/verify/${encodeURIComponent(reference)}`,
  );
  if (!result.ok || !result.status) {
    return errorResponse(result.message || "Verification failed", 502);
  }

  const txn = result.data;
  const charged = txn.status === "success";

  if (!charged) {
    return jsonResponse({ status: txn.status ?? "failed", plan: "free" });
  }

  // Defense in depth: only grant premium to the authenticated caller. If
  // Paystack metadata carries a different user_id, trust the JWT, not the body.
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const customerCode = txn.customer?.customer_code ?? null;
  const paidAt = txn.paid_at ?? new Date().toISOString();
  const metaType = txn.metadata?.type;

  if (metaType === "wallet_top_up") {
    const amountNgn = paystackAmountToMajor(txn.amount);
    const cowries = ngnToCowries(amountNgn);

    if (cowries <= 0) {
      return errorResponse(
        "Top-up amount below minimum (₦1,000 = 50 cowries)",
        400,
      );
    }

    const { error: creditErr } = await admin.rpc("credit_wallet_cowries", {
      p_user_id: userId,
      p_amount_cowries: cowries,
      p_reference: txn.reference ?? reference,
      p_fiat_amount: amountNgn,
      p_currency: txn.currency ?? "NGN",
    });
    if (creditErr) {
      return errorResponse(`Failed to credit wallet: ${creditErr.message}`, 500);
    }

    const ledgerRef = txn.reference ?? reference;
    const ledgerErr = await upsertPaymentTransaction(admin, {
      user_id: userId,
      reference: ledgerRef,
      amount: amountNgn,
      currency: txn.currency ?? "NGN",
      status: ledgerStatusFromTxn(txn.status),
      paystack_event: "wallet_top_up.verify",
      metadata: { reference, cowries, amount_ngn: amountNgn },
    });
    if (ledgerErr) {
      return errorResponse(`Failed to record payment ledger: ${ledgerErr}`, 500);
    }

    return jsonResponse({ status: "success", plan: "wallet" });
  }

  const { error: upsertErr } = await admin
    .from("subscriptions")
    .upsert(
      {
        user_id: userId,
        plan: "premium",
        status: "active",
        paystack_customer_code: customerCode,
        current_period_start: paidAt,
        // current_period_end is refined by the subscription.create / invoice
        // webhooks; null here means "valid until the webhook updates it".
      },
      { onConflict: "user_id" },
    );

  if (upsertErr) {
    return errorResponse(`Failed to record subscription: ${upsertErr.message}`, 500);
  }

  const ledgerRef = txn.reference ?? reference;
  const ledgerErr = await upsertPaymentTransaction(admin, {
    user_id: userId,
    reference: ledgerRef,
    amount: paystackAmountToMajor(txn.amount),
    currency: txn.currency ?? "NGN",
    status: ledgerStatusFromTxn(txn.status),
    paystack_event: "transaction.verify",
    metadata: { reference },
  });
  if (ledgerErr) {
    return errorResponse(`Failed to record payment ledger: ${ledgerErr}`, 500);
  }

  return jsonResponse({ status: "success", plan: "premium" });
});
