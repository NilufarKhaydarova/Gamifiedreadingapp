// ─── RAG Retrieval ────────────────────────────────────────────────────────────
// Two paths:
//   1. retrieve-to-question  → spoiler-safe top-K by cosine similarity
//   2. cross-episode callbacks → MMR-diversified (λ=0.5), may cross episodes
//
// SPOILER INVARIANT: relevant[] chunks always satisfy episodeIndex ≤ currentEpisodeIndex.
// Callback chunks MAY have higher episodeIndex — they surface narrative echoes —
// but the companion prompt is instructed never to reveal future events verbatim.

import { getChunksSpoilerSafe, getChunksByBook, getEmbeddingsByIds } from './db';
import { embedOne } from './embeddings';
import type { BookChunk, RetrievedChunk, CompanionRetrievalContext } from './types';

const TOP_K_RELEVANT = 5;
const TOP_K_CALLBACKS = 3;
const MMR_LAMBDA = 0.5; // balance between relevance and diversity

// ── Math helpers ──────────────────────────────────────────────────────────────

export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) return 0;
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  const denom = Math.sqrt(normA) * Math.sqrt(normB);
  return denom === 0 ? 0 : dot / denom;
}

// ── Ranked retrieval ──────────────────────────────────────────────────────────

interface ScoredChunk {
  chunk: BookChunk;
  embedding: number[];
  score: number;
}

async function rankChunks(
  queryEmbedding: number[],
  chunks: BookChunk[],
): Promise<ScoredChunk[]> {
  if (chunks.length === 0) return [];

  const chunkIds = chunks.map((c) => c.id!).filter(Boolean);
  const embMap = await getEmbeddingsByIds(chunkIds);

  const scored: ScoredChunk[] = [];
  for (const chunk of chunks) {
    if (chunk.id == null) continue;
    const emb = embMap.get(chunk.id);
    if (!emb) continue; // no embedding yet — skip
    scored.push({
      chunk,
      embedding: emb.embedding,
      score: cosineSimilarity(queryEmbedding, emb.embedding),
    });
  }

  return scored.sort((a, b) => b.score - a.score);
}

// ── MMR selection ─────────────────────────────────────────────────────────────

/**
 * Maximal Marginal Relevance selection (Carbonell & Goldstein, 1998).
 * Balances relevance to the query with diversity among selected chunks.
 *
 * score_mmr(d) = λ · sim(d, query) - (1-λ) · max_{s∈selected} sim(d, s)
 */
function mmrSelect(candidates: ScoredChunk[], topK: number): ScoredChunk[] {
  if (candidates.length === 0) return [];
  const selected: ScoredChunk[] = [];
  const remaining = [...candidates];

  while (selected.length < topK && remaining.length > 0) {
    let bestIdx = 0;
    let bestScore = -Infinity;

    for (let i = 0; i < remaining.length; i++) {
      const relevance = remaining[i].score;
      const redundancy =
        selected.length === 0
          ? 0
          : Math.max(...selected.map((s) => cosineSimilarity(remaining[i].embedding, s.embedding)));
      const mmrScore = MMR_LAMBDA * relevance - (1 - MMR_LAMBDA) * redundancy;
      if (mmrScore > bestScore) {
        bestScore = mmrScore;
        bestIdx = i;
      }
    }

    selected.push(remaining[bestIdx]);
    remaining.splice(bestIdx, 1);
  }

  return selected;
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Path 1 — retrieve-to-question.
 * Returns up to TOP_K_RELEVANT chunks with episodeIndex ≤ currentEpisodeIndex.
 * Enforces the spoiler-safety invariant at the storage query level.
 */
export async function retrieveRelevant(
  query: string,
  bookId: string,
  currentEpisodeIndex: number,
  topK = TOP_K_RELEVANT,
): Promise<RetrievedChunk[]> {
  const { embedding: queryEmbedding } = await embedOne(query);
  const safeChunks = await getChunksSpoilerSafe(bookId, currentEpisodeIndex);
  const ranked = await rankChunks(queryEmbedding, safeChunks);

  return ranked.slice(0, topK).map((s) => ({
    chunk: s.chunk,
    score: s.score,
    isCallback: false,
  }));
}

/**
 * Path 2 — cross-episode callback retrieval.
 * Uses MMR over ALL chunks (no spoiler filter) to surface narrative echoes.
 * The companion prompt instructs Claude never to reveal future events verbatim.
 */
export async function retrieveCallbacks(
  query: string,
  bookId: string,
  topK = TOP_K_CALLBACKS,
): Promise<RetrievedChunk[]> {
  const { embedding: queryEmbedding } = await embedOne(query);
  const allChunks = await getChunksByBook(bookId);
  const ranked = await rankChunks(queryEmbedding, allChunks);
  const diverse = mmrSelect(ranked, topK);

  return diverse.map((s) => ({
    chunk: s.chunk,
    score: s.score,
    isCallback: true,
  }));
}

/**
 * Combined retrieval entry point — used by the companion.
 * Re-uses a single query embedding for both paths.
 */
export async function companionRetrieve(
  query: string,
  bookId: string,
  currentEpisodeIndex: number,
): Promise<CompanionRetrievalContext> {
  // Embed the query once, then run both retrieval paths in parallel.
  const { embedding: queryEmbedding } = await embedOne(query);

  const [safeChunks, allChunks] = await Promise.all([
    getChunksSpoilerSafe(bookId, currentEpisodeIndex),
    getChunksByBook(bookId),
  ]);

  const [rankedRelevant, rankedAll] = await Promise.all([
    rankChunks(queryEmbedding, safeChunks),
    rankChunks(queryEmbedding, allChunks),
  ]);

  const relevant = rankedRelevant.slice(0, TOP_K_RELEVANT).map((s) => ({
    chunk: s.chunk,
    score: s.score,
    isCallback: false,
  }));

  const diverse = mmrSelect(rankedAll, TOP_K_CALLBACKS);
  const callbacks = diverse.map((s) => ({
    chunk: s.chunk,
    score: s.score,
    isCallback: true,
  }));

  // Spoiler-safety assertion (belt + suspenders)
  for (const r of relevant) {
    if (r.chunk.episodeIndex > currentEpisodeIndex) {
      throw new Error(
        `[RAG] SPOILER VIOLATION: chunk ${r.chunk.id} has episodeIndex ${r.chunk.episodeIndex} > current ${currentEpisodeIndex}`,
      );
    }
  }

  return { relevant, callbacks };
}
