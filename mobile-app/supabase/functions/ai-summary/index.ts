// ai-summary/index.ts
// Generates a book or chapter summary via an LLM provider and caches the
// result in the `ai_summaries` table (one row per book+chapter_ref+type).
//
// Request  (POST, JSON):
//   { "bookId": "<uuid>", "summaryType": "book" | "chapter", "chapterRef": "ch-3" }
// Response (200, JSON):
//   { "summary": "...", "cached": true | false }
//
// Secrets / env:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (auto-injected)
//   LLM_API_KEY        — provider API key (e.g. OpenAI/Anthropic)
//   LLM_MODEL          — optional model id (default below)
//
// Deploy:  supabase functions deploy ai-summary

import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const LLM_API_KEY = Deno.env.get("LLM_API_KEY") ?? "";
const LLM_MODEL = Deno.env.get("LLM_MODEL") ?? "gpt-4o-mini";

type SummaryType = "book" | "chapter";

Deno.serve(async (req) => {
  const pre = handleCors(req);
  if (pre) return pre;
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return errorResponse("Missing bearer token", 401);
  }

  let body: { bookId?: string; summaryType?: SummaryType; chapterRef?: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { bookId } = body;
  const summaryType: SummaryType = body.summaryType ?? "book";
  const chapterRef = body.chapterRef ?? null;
  if (!bookId) return errorResponse("bookId is required", 400);
  if (summaryType === "chapter" && !chapterRef) {
    return errorResponse("chapterRef is required for chapter summaries", 400);
  }

  // Verify caller is authenticated.
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return errorResponse("Unauthorized", 401);

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // 1) Cache hit? chapter_ref is NULL for whole-book summaries.
  let cacheQuery = admin
    .from("ai_summaries")
    .select("content")
    .eq("book_id", bookId)
    .eq("summary_type", summaryType);
  cacheQuery = chapterRef === null
    ? cacheQuery.is("chapter_ref", null)
    : cacheQuery.eq("chapter_ref", chapterRef);
  const { data: cached } = await cacheQuery.maybeSingle();

  if (cached?.content) {
    return jsonResponse({ summary: cached.content, cached: true });
  }

  // 2) Load book context.
  const { data: book, error: bookErr } = await admin
    .from("books")
    .select("title, author, description")
    .eq("id", bookId)
    .single();
  if (bookErr || !book) return errorResponse("Book not found", 404);

  // 3) Call the LLM provider.
  // TODO: replace this stub with a real provider call. Pull actual book/chapter
  // text from storage (book-files) where licensing allows, and chunk/summarize.
  let summary: string;
  try {
    summary = await generateSummary({
      title: book.title,
      author: book.author,
      description: book.description ?? "",
      summaryType,
      chapterRef,
    });
  } catch (e) {
    return errorResponse(`LLM error: ${(e as Error).message}`, 502);
  }

  // 4) Cache (best-effort; ignore unique-conflict races).
  await admin.from("ai_summaries").upsert(
    {
      book_id: bookId,
      summary_type: summaryType,
      chapter_ref: chapterRef,
      content: summary,
    },
    { onConflict: "book_id,summary_type,chapter_ref", ignoreDuplicates: true },
  );

  return jsonResponse({ summary, cached: false });
});

// ---------------------------------------------------------------------
// LLM provider call — STUB. Wire to your provider of choice.
// ---------------------------------------------------------------------
async function generateSummary(input: {
  title: string;
  author: string;
  description: string;
  summaryType: SummaryType;
  chapterRef: string | null;
}): Promise<string> {
  const scope =
    input.summaryType === "chapter"
      ? `chapter "${input.chapterRef}" of`
      : "the book";

  const prompt =
    `Summarize ${scope} "${input.title}" by ${input.author}. ` +
    `Context: ${input.description}. Provide a concise, spoiler-aware summary.`;

  if (!LLM_API_KEY) {
    // No key configured — return a deterministic placeholder so local dev works.
    return `[[STUB SUMMARY — set LLM_API_KEY to enable]]\n${prompt}`;
  }

  // TODO: implement the real request. Example (OpenAI-compatible):
  //
  // const res = await fetch("https://api.openai.com/v1/chat/completions", {
  //   method: "POST",
  //   headers: {
  //     Authorization: `Bearer ${LLM_API_KEY}`,
  //     "Content-Type": "application/json",
  //   },
  //   body: JSON.stringify({
  //     model: LLM_MODEL,
  //     messages: [{ role: "user", content: prompt }],
  //   }),
  // });
  // const json = await res.json();
  // return json.choices[0].message.content as string;

  return `[[TODO: call ${LLM_MODEL}]]\n${prompt}`;
}
