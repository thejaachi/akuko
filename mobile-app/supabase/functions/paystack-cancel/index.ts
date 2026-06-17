// paystack-cancel/index.ts
// Disables (cancels auto-renewal of) the caller's Paystack subscription.
// Paystack's /subscription/disable needs the subscription `code` plus its
// `email_token`, which we fetch server-side. After disabling, the actual
// `subscriptions` row transition is driven by the `subscription.disable`
// webhook; we optimistically mark it non-renewing for instant UI feedback.
//
// Request  (POST, JSON):  {}   (subscription resolved from the caller)
// Response (200, JSON):   { "status": "non-renewing" }
// Auth: requires the caller's Supabase JWT (verify_jwt = true).
//
// Secrets / env:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (auto-injected)
//   PAYSTACK_SECRET_KEY
//
// Deploy:  supabase functions deploy paystack-cancel

import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { paystackFetch, PAYSTACK_SECRET_KEY } from "../_shared/paystack.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

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

  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return errorResponse("Unauthorized", 401);
  const userId = userData.user.id;

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data: sub } = await admin
    .from("subscriptions")
    .select("paystack_subscription_code")
    .eq("user_id", userId)
    .maybeSingle();

  const code = sub?.paystack_subscription_code;
  if (!code) {
    return errorResponse("No active subscription to cancel", 404);
  }

  // Fetch the subscription to obtain its email_token (required to disable).
  const detail = await paystackFetch<{ email_token?: string }>(
    `/subscription/${encodeURIComponent(code)}`,
  );
  if (!detail.ok || !detail.status || !detail.data.email_token) {
    return errorResponse(detail.message || "Could not load subscription", 502);
  }

  const disable = await paystackFetch("/subscription/disable", {
    method: "POST",
    body: JSON.stringify({ code, token: detail.data.email_token }),
  });
  if (!disable.ok || !disable.status) {
    return errorResponse(disable.message || "Failed to cancel subscription", 502);
  }

  // Optimistic local transition; the subscription.disable webhook reconciles
  // the authoritative state (and the exact period end).
  await admin
    .from("subscriptions")
    .update({ status: "non-renewing" })
    .eq("user_id", userId);

  return jsonResponse({ status: "non-renewing" });
});
