// reading-assistant/index.ts
// Conversational Q&A assistant scoped to a single book. Answers reader
// questions ("who is this character?", "explain this passage") using the
// book's content as context (RAG-style).
//
// Request  (POST, JSON):
//   {
//     "bookId": "<uuid>",
//     "question": "Who betrayed the protagonist?",
//     "context": "optional selected passage / current location text",
//     "history": [{ "role": "user"|"assistant", "content": "..." }]
//   }
// Response (200, JSON):
//   { "answer": "...", "citations": [{ "location": "...", "snippet": "..." }] }
//
// Secrets / env:
//   SUPABASE_URL, SUPABASE_ANON_KEY (auto-injected)
//   LLM_API_KEY, LLM_MODEL
//   (optional) EMBEDDINGS_API_KEY for vector retrieval over book chunks
//
// Deploy:  supabase functions deploy reading-assistant

import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const LLM_API_KEY = Deno.env.get("LLM_API_KEY") ?? "";
const LLM_MODEL = Deno.env.get("LLM_MODEL") ?? "gpt-4o-mini";

interface ChatTurn {
  role: "user" | "assistant";
  content: string;
}

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
    question?: string;
    context?: string;
    history?: ChatTurn[];
  };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { bookId, question } = body;
  if (!bookId) return errorResponse("bookId is required", 400);
  if (!question) return errorResponse("question is required", 400);

  // Authenticated callers only.
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return errorResponse("Unauthorized", 401);

  // Book metadata is readable under RLS (books are public-read).
  const { data: book, error: bookErr } = await userClient
    .from("books")
    .select("title, author, description")
    .eq("id", bookId)
    .single();
  if (bookErr || !book) return errorResponse("Book not found", 404);

  // TODO (RAG): retrieve the most relevant book chunks for `question`
  // (e.g. pgvector similarity search over a `book_chunks` table populated by
  // an ingestion job), then pass them to the LLM as grounding context.
  const retrieved: { location: string; snippet: string }[] = [];

  let answer: string;
  try {
    answer = await answerQuestion({
      title: book.title,
      author: book.author,
      description: book.description ?? "",
      question,
      selection: body.context ?? "",
      history: body.history ?? [],
      retrieved,
    });
  } catch (e) {
    return errorResponse(`LLM error: ${(e as Error).message}`, 502);
  }

  return jsonResponse({ answer, citations: retrieved });
});

// ---------------------------------------------------------------------
// LLM call — STUB.
// ---------------------------------------------------------------------
async function answerQuestion(input: {
  title: string;
  author: string;
  description: string;
  question: string;
  selection: string;
  history: ChatTurn[];
  retrieved: { location: string; snippet: string }[];
}): Promise<string> {
  const grounding = input.retrieved.map((r) => `- ${r.snippet}`).join("\n");
  const system =
    `You are a helpful reading assistant for "${input.title}" by ` +
    `${input.author}. Answer ONLY using the provided context; avoid spoilers ` +
    `beyond the reader's current location when possible.`;

  if (!LLM_API_KEY) {
    return `[[STUB ANSWER — set LLM_API_KEY to enable]]\nQ: ${input.question}`;
  }

  // TODO: implement the real chat completion call using `system`, the
  // retrieved `grounding`, conversation `history`, current `selection`,
  // and the user's `question`. Return the assistant's reply text.
  void system;
  void grounding;
  return `[[TODO: call ${LLM_MODEL}]]\nQ: ${input.question}`;
}
