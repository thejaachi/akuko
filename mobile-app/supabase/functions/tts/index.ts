// tts/index.ts
// Text-to-speech audiobook generation stub. Converts a chunk of book text
// (e.g. a chapter) into synthesized audio, uploads it to storage, and returns
// a playable URL. Long jobs should be processed asynchronously.
//
// Request  (POST, JSON):
//   {
//     "bookId": "<uuid>",
//     "chapterRef": "ch-1",
//     "text": "….",          // text to synthesize (or omit to fetch server-side)
//     "voice": "en-US-Standard-A",
//     "format": "mp3"
//   }
// Response (202, JSON):  { "status": "processing", "jobId": "..." }
//   or (200, JSON):      { "audioUrl": "https://...", "durationSec": 1234 }
//
// Secrets / env:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (auto-injected)
//   TTS_API_KEY        — provider key (e.g. ElevenLabs / Google / Azure)
//   TTS_PROVIDER       — provider id (default below)
//
// Deploy:  supabase functions deploy tts

import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TTS_API_KEY = Deno.env.get("TTS_API_KEY") ?? "";
const TTS_PROVIDER = Deno.env.get("TTS_PROVIDER") ?? "elevenlabs";
const AUDIO_BUCKET = "book-files"; // store generated audio alongside book files

Deno.serve(async (req) => {
  const pre = handleCors(req);
  if (pre) return pre;
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return errorResponse("Missing bearer token", 401);
  }

  let body: {
    bookId?: string;
    chapterRef?: string;
    text?: string;
    voice?: string;
    format?: string;
  };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { bookId } = body;
  const chapterRef = body.chapterRef ?? "full";
  const voice = body.voice ?? "default";
  const format = body.format ?? "mp3";
  if (!bookId) return errorResponse("bookId is required", 400);

  // Authenticated callers only.
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return errorResponse("Unauthorized", 401);
  const userId = userData.user.id;

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // TTS is a premium feature — require valid premium entitlement. Derived from
  // the canonical `subscriptions` table via the `is_premium(uid)` SQL helper
  // (see 0006_subscriptions.sql).
  const { data: entitled, error: entErr } = await admin.rpc("is_premium", {
    uid: userId,
  });
  if (entErr || entitled !== true) {
    return errorResponse("Premium subscription required", 402);
  }

  // TODO: 1) Resolve text to synthesize (from `body.text` or by extracting the
  //          chapter from the book file in storage).
  //       2) Call the TTS provider (`TTS_PROVIDER`) to synthesize audio.
  //       3) Upload the audio to `${AUDIO_BUCKET}/audio/<bookId>/<chapterRef>.<format>`.
  //       4) For long content, enqueue a background job and return 202 + jobId,
  //          then notify the user via the notifications table when complete.

  if (!TTS_API_KEY) {
    return jsonResponse(
      {
        status: "not_configured",
        message: "Set TTS_API_KEY to enable audiobook generation.",
        requested: { bookId, chapterRef, voice, format, provider: TTS_PROVIDER },
      },
      501,
    );
  }

  const objectPath = `audio/${bookId}/${chapterRef}.${format}`;
  void AUDIO_BUCKET;
  void objectPath;

  return jsonResponse(
    { status: "processing", jobId: crypto.randomUUID() },
    202,
  );
});
