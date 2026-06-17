// signed-url/index.ts
// Issues a time-limited signed URL for a file in the private `book-files`
// bucket, enforcing premium / subscription entitlement.
//
// Request  (POST, JSON):  { "bookId": "<uuid>", "expiresIn": 3600 }
// Response (200, JSON):   { "signedUrl": "https://...", "expiresIn": 3600 }
// Auth: requires the caller's Supabase JWT in the Authorization header.
//
// Secrets / env (set via `supabase secrets set ...`):
//   SUPABASE_URL                 (auto-injected)
//   SUPABASE_ANON_KEY            (auto-injected)
//   SUPABASE_SERVICE_ROLE_KEY    (auto-injected) — used to mint signed URLs
//
// Deploy:  supabase functions deploy signed-url

import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BUCKET = "book-files";
const DEFAULT_EXPIRES_IN = 60 * 60; // 1 hour

Deno.serve(async (req) => {
  const pre = handleCors(req);
  if (pre) return pre;

  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return errorResponse("Missing bearer token", 401);
  }

  let body: { bookId?: string; expiresIn?: number };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const bookId = body.bookId;
  const expiresIn = body.expiresIn ?? DEFAULT_EXPIRES_IN;
  if (!bookId) return errorResponse("bookId is required", 400);

  // Client scoped to the caller (RLS-aware) to resolve their identity.
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return errorResponse("Unauthorized", 401);
  const userId = userData.user.id;

  // Service-role client bypasses RLS for entitlement checks + URL minting.
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  const { data: book, error: bookErr } = await admin
    .from("books")
    .select("id, file_url, is_premium")
    .eq("id", bookId)
    .single();

  if (bookErr || !book) return errorResponse("Book not found", 404);
  if (!book.file_url) return errorResponse("Book has no file", 409);

  // Premium gating: premium books require valid premium entitlement.
  // Entitlement is derived from the canonical `subscriptions` table via the
  // `is_premium(uid)` SQL helper (see 0006_subscriptions.sql).
  if (book.is_premium) {
    const { data: entitled, error: entErr } = await admin.rpc("is_premium", {
      uid: userId,
    });
    if (entErr || entitled !== true) {
      return errorResponse("Premium subscription required", 402);
    }
  }

  // file_url is stored as "book-files/<path>"; strip the bucket prefix.
  const objectPath = book.file_url.replace(/^book-files\//, "");

  const { data: signed, error: signErr } = await admin.storage
    .from(BUCKET)
    .createSignedUrl(objectPath, expiresIn);

  if (signErr || !signed) {
    return errorResponse(`Failed to sign URL: ${signErr?.message}`, 500);
  }

  // TODO: optionally increment books.download_count here.
  return jsonResponse({ signedUrl: signed.signedUrl, expiresIn });
});
