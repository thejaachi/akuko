// paystack-initialize/index.ts
// Initializes a Paystack transaction server-side (using the secret key) and
// returns the hosted checkout `authorization_url` + `reference`. The client
// opens the URL in a WebView; payment is confirmed ONLY server-side (verify +
// webhook). The client never sees the secret key.
//
// Request  (POST, JSON):
//   {
//     "planCode": "PLN_xxx",      // Paystack plan code (creates a subscription)
//     "amount": 999900,           // optional, minor units (kobo) — used if no plan
//     "currency": "NGN",          // optional
//     "callbackUrl": "https://akuko.app/paystack/callback" // WebView sentinel
//   }
// Response (200, JSON):
//   { "authorizationUrl": "https://checkout.paystack.com/...",
//     "accessCode": "...", "reference": "..." }
// Auth: requires the caller's Supabase JWT (verify_jwt = true).
//
// Secrets / env:
//   SUPABASE_URL, SUPABASE_ANON_KEY (auto-injected)
//   PAYSTACK_SECRET_KEY
//
// Deploy:  supabase functions deploy paystack-initialize

import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { paystackFetch, PAYSTACK_SECRET_KEY } from "../_shared/paystack.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const DEFAULT_CALLBACK = "https://akuko.app/paystack/callback";

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

  let body: {
    planCode?: string;
    amount?: number;
    currency?: string;
    callbackUrl?: string;
    email?: string;
    metadata?: Record<string, unknown>;
  };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  // Resolve the caller identity from their JWT (never trust a client-sent id).
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return errorResponse("Unauthorized", 401);
  const user = userData.user;
  const email = user.email ?? body.email;
  if (!email) return errorResponse("User has no email for billing", 400);

  if (!body.planCode && !body.amount) {
    return errorResponse("Either planCode or amount is required", 400);
  }

  const payload: Record<string, unknown> = {
    email,
    callback_url: body.callbackUrl ?? DEFAULT_CALLBACK,
    metadata: {
      user_id: user.id,
      ...(body.metadata ?? {}),
    },
  };
  if (body.planCode) payload.plan = body.planCode;
  if (body.amount) payload.amount = body.amount;
  if (body.currency) payload.currency = body.currency;

  const result = await paystackFetch<{
    authorization_url: string;
    access_code: string;
    reference: string;
  }>("/transaction/initialize", {
    method: "POST",
    body: JSON.stringify(payload),
  });

  if (!result.ok || !result.status) {
    return errorResponse(
      result.message || "Failed to initialize transaction",
      502,
    );
  }

  return jsonResponse({
    authorizationUrl: result.data.authorization_url,
    accessCode: result.data.access_code,
    reference: result.data.reference,
  });
});
