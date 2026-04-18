// ─── Socratic AI Companion ────────────────────────────────────────────────────
// Claude Sonnet 4 via Anthropic Messages API.
// Injects <retrieved_context> and <callbacks> blocks into the system prompt.
// Spoiler-safe: context blocks are pre-filtered by the retrieval layer.

import type { CompanionRetrievalContext } from './types';

export type ChatMode = 'socratic' | 'discussion' | 'quiz';

export interface ConversationMessage {
  role: 'user' | 'assistant';
  content: string;
}

const ANTHROPIC_API = 'https://api.anthropic.com/v1/messages';
const MODEL = 'claude-sonnet-4-5';
const MAX_TOKENS = 800;

function anthropicKey(): string | undefined {
  return (import.meta as any).env?.VITE_ANTHROPIC_API_KEY;
}

// ── System prompt builder ─────────────────────────────────────────────────────

function buildSystemPrompt(
  bookTitle: string,
  bookAuthor: string,
  mode: ChatMode,
  currentEpisodeIndex: number,
  totalChunks: number,
  context: CompanionRetrievalContext,
): string {
  const modeInstructions: Record<ChatMode, string> = {
    socratic: `You are a Socratic tutor. Guide the reader to deeper understanding through
thoughtful questions. Never give away answers — ask probing follow-ups instead.
Encourage the reader to find evidence in the text and articulate their own interpretations.`,

    discussion: `You are an engaged book club facilitator. Discuss themes, characters, and
ideas with warmth and curiosity. Stay strictly within what the reader has read so far —
never spoil upcoming events. Invite the reader to share their reactions.`,

    quiz: `You are a reading comprehension coach. Quiz the reader on the text they have read.
Ask one question at a time. After the reader answers, give constructive feedback that
references the text. Tailor difficulty to how much they have read.`,
  };

  const relevantSection =
    context.relevant.length > 0
      ? context.relevant
          .map(
            (r) =>
              `[Section ${r.chunk.episodeIndex + 1} — ${r.chunk.episodeTitle}]\n${r.chunk.content}`,
          )
          .join('\n\n---\n\n')
      : '(No relevant passages found for this query.)';

  const callbackSection =
    context.callbacks.length > 0
      ? context.callbacks
          .map(
            (r) =>
              `[Section ${r.chunk.episodeIndex + 1} — ${r.chunk.episodeTitle}]\n${r.chunk.content}`,
          )
          .join('\n\n---\n\n')
      : '(No callbacks found.)';

  return `You are an AI reading companion for "${bookTitle}" by ${bookAuthor}.
The reader is at section ${currentEpisodeIndex + 1} of ${totalChunks}.

${modeInstructions[mode]}

CRITICAL RULE — SPOILER SAFETY:
You MUST NOT reveal, hint at, or allude to any events, characters, or information
from sections the reader has not yet reached. The <retrieved_context> block below
has already been filtered to be spoiler-safe. The <callbacks> block may reference
later sections — use them ONLY as background awareness to ask richer questions;
never paraphrase or quote their specific content if it is beyond the reader's position.

<retrieved_context>
${relevantSection}
</retrieved_context>

<callbacks>
${callbackSection}
</callbacks>

Use the retrieved context to ground your response in actual text from the book.
Quote briefly when helpful. Be concise (2–4 paragraphs max). Respond in the same
language the reader uses (supports English, Russian, Uzbek).`;
}

// ── Anthropic API call ────────────────────────────────────────────────────────

async function callClaude(
  systemPrompt: string,
  history: ConversationMessage[],
): Promise<string> {
  const key = anthropicKey();
  if (!key) {
    throw new Error('VITE_ANTHROPIC_API_KEY not set. Add it to your .env file.');
  }

  const response = await fetch(ANTHROPIC_API, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': key,
      'anthropic-version': '2023-06-01',
      'anthropic-dangerous-direct-browser-access': 'true',
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: systemPrompt,
      messages: history.map((m) => ({ role: m.role, content: m.content })),
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Anthropic API error ${response.status}: ${err}`);
  }

  const json = await response.json();
  const content = json.content as { type: string; text: string }[];
  const textBlock = content.find((c) => c.type === 'text');
  return textBlock?.text ?? '(No response)';
}

// ── Public entry point ────────────────────────────────────────────────────────

/**
 * Ask the Socratic Companion a question with RAG context.
 *
 * @param userMessage   The latest user message.
 * @param mode          Conversation mode (socratic | discussion | quiz).
 * @param context       Retrieval context from companionRetrieve().
 * @param bookTitle     Book title for the system prompt.
 * @param bookAuthor    Book author.
 * @param currentEpisodeIndex  Reader's current position (0-based chunk index).
 * @param totalChunks   Total chunk count for progress display.
 * @param history       Prior conversation messages (excluding the latest user msg).
 */
export async function askCompanion(
  userMessage: string,
  mode: ChatMode,
  context: CompanionRetrievalContext,
  bookTitle: string,
  bookAuthor: string,
  currentEpisodeIndex: number,
  totalChunks: number,
  history: ConversationMessage[],
): Promise<string> {
  const systemPrompt = buildSystemPrompt(
    bookTitle,
    bookAuthor,
    mode,
    currentEpisodeIndex,
    totalChunks,
    context,
  );

  // Append the current user message to history for the API call
  const messages: ConversationMessage[] = [
    ...history,
    { role: 'user', content: userMessage },
  ];

  return callClaude(systemPrompt, messages);
}

// ── Graceful fallback (no API key / no embeddings) ────────────────────────────

export function fallbackResponse(mode: ChatMode, bookTitle: string): string {
  const templates: Record<ChatMode, string> = {
    socratic: `That's a thought-provoking question about "${bookTitle}". What evidence from the text supports your thinking? What alternative interpretations might be possible?`,
    discussion: `The themes you're picking up on in "${bookTitle}" are worth exploring. What connections are you making between what you've read and your own experience?`,
    quiz: `I'd love to quiz you on "${bookTitle}"! What aspect of the story would you like to be tested on — characters, themes, plot, or writing style?`,
  };
  return templates[mode];
}
