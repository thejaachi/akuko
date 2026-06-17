// _shared/cors.ts
// Shared CORS handling for all Akuko edge functions.
//
// Usage:
//   import { corsHeaders, handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
//   const pre = handleCors(req);
//   if (pre) return pre;
//   ...
//   return jsonResponse({ ok: true });

// In production, lock this down to your app's origins (web build, etc.).
// Mobile (Flutter) clients are not subject to browser CORS, but the web
// build and local dev tooling are.
const ALLOWED_ORIGIN = Deno.env.get("CORS_ALLOW_ORIGIN") ?? "*";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

/** Returns a 204 preflight response when the request is an OPTIONS call. */
export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  return null;
}

/** JSON success helper that always attaches CORS headers. */
export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** JSON error helper. */
export function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status);
}
