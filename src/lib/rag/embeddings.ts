// ─── Embedding Generation ─────────────────────────────────────────────────────
// Primary: Voyage voyage-multilingual-2 (1024 dims, supports en/ru/uz).
// Fallback: OpenAI text-embedding-3-small (1536 dims).

const VOYAGE_URL = 'https://api.voyageai.com/v1/embeddings';
const OPENAI_URL = 'https://api.openai.com/v1/embeddings';

export type EmbeddingProvider = 'voyage' | 'openai';

function voyageKey(): string | undefined {
  return (import.meta as any).env?.VITE_VOYAGE_API_KEY;
}
function openaiKey(): string | undefined {
  return (import.meta as any).env?.VITE_OPENAI_API_KEY;
}

/** Resolve which provider to use at runtime. */
export function resolveProvider(): EmbeddingProvider {
  const pref = ((import.meta as any).env?.VITE_RAG_EMBEDDING_PROVIDER ?? '').toLowerCase();
  if (pref === 'openai') return 'openai';
  if (pref === 'voyage' && voyageKey()) return 'voyage';
  if (voyageKey()) return 'voyage';
  if (openaiKey()) return 'openai';
  throw new Error(
    'No embedding API key found. Set VITE_VOYAGE_API_KEY or VITE_OPENAI_API_KEY.',
  );
}

// ── Voyage ────────────────────────────────────────────────────────────────────

async function embedVoyage(texts: string[]): Promise<number[][]> {
  const key = voyageKey();
  if (!key) throw new Error('VITE_VOYAGE_API_KEY not set');

  const res = await fetch(VOYAGE_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify({
      model: 'voyage-multilingual-2',
      input: texts,
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Voyage API error ${res.status}: ${err}`);
  }

  const json = await res.json();
  // Voyage response: { data: [{ embedding: number[] }, ...] }
  return (json.data as { embedding: number[] }[]).map((d) => d.embedding);
}

// ── OpenAI ────────────────────────────────────────────────────────────────────

async function embedOpenAI(texts: string[]): Promise<number[][]> {
  const key = openaiKey();
  if (!key) throw new Error('VITE_OPENAI_API_KEY not set');

  const res = await fetch(OPENAI_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: texts,
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenAI embeddings error ${res.status}: ${err}`);
  }

  const json = await res.json();
  // OpenAI response: { data: [{ embedding: number[] }, ...] }
  return (json.data as { embedding: number[] }[]).map((d) => d.embedding);
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Embed a batch of texts.
 * Tries Voyage first; falls back to OpenAI on failure.
 * Returns { embeddings, model }.
 */
export async function embedBatch(
  texts: string[],
): Promise<{ embeddings: number[][]; model: string }> {
  const provider = resolveProvider();

  if (provider === 'voyage') {
    try {
      const embeddings = await embedVoyage(texts);
      return { embeddings, model: 'voyage-multilingual-2' };
    } catch (e) {
      console.warn('[RAG] Voyage failed, trying OpenAI fallback:', e);
    }
  }

  const embeddings = await embedOpenAI(texts);
  return { embeddings, model: 'text-embedding-3-small' };
}

/**
 * Embed a single text string.
 */
export async function embedOne(
  text: string,
): Promise<{ embedding: number[]; model: string }> {
  const { embeddings, model } = await embedBatch([text]);
  return { embedding: embeddings[0], model };
}
