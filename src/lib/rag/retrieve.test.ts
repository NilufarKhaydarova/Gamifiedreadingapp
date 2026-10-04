import { describe, it, expect, beforeEach, vi } from 'vitest';
import type { BookChunk, ChunkEmbedding } from './types';

vi.mock('./embeddings', () => ({ embedOne: vi.fn() }));
vi.mock('./db', () => ({
  getChunksByBook: vi.fn(),
  getChunksSpoilerSafe: vi.fn(),
  getEmbeddingsByIds: vi.fn(),
}));

import { embedOne } from './embeddings';
import * as db from './db';
import {
  cosineSimilarity,
  retrieveRelevant,
  retrieveCallbacks,
  companionRetrieve,
} from './retrieve';

const mkChunk = (id: number): BookChunk => ({
  id,
  bookId: 'b',
  chunkNumber: id - 1,
  episodeIndex: id - 1,
  episodeTitle: `Section ${id}`,
  content: `chunk ${id}`,
  startOffset: 0,
  endOffset: 1,
});

// 6 chunks; embeddings chosen so similarity to query [1, 0] is known.
const chunks = [1, 2, 3, 4, 5, 6].map(mkChunk);
const vectors: Record<number, number[]> = {
  1: [0, 1], // orthogonal → 0
  2: [1, 1], // ~0.707
  3: [1, 0.1], // ~0.995
  4: [1, 0], // 1.0 (but future episode in some tests)
  5: [1, 0.05], // ~0.999 (near-duplicate of 4)
  6: [-1, 0], // -1
};

function embMap(ids: number[]) {
  const m = new Map<number, ChunkEmbedding>();
  ids.forEach((id) => {
    if (vectors[id]) m.set(id, { chunkId: id, embedding: vectors[id], model: 'm', createdAt: '' });
  });
  return m;
}

describe('cosineSimilarity', () => {
  it('is 1 for identical direction, 0 for orthogonal, -1 for opposite', () => {
    expect(cosineSimilarity([2, 0], [5, 0])).toBeCloseTo(1);
    expect(cosineSimilarity([1, 0], [0, 1])).toBeCloseTo(0);
    expect(cosineSimilarity([1, 0], [-1, 0])).toBeCloseTo(-1);
  });

  it('returns 0 for mismatched lengths or zero vectors', () => {
    expect(cosineSimilarity([1, 2], [1, 2, 3])).toBe(0);
    expect(cosineSimilarity([0, 0], [1, 1])).toBe(0);
  });
});

describe('retrieval', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(embedOne).mockResolvedValue({ embedding: [1, 0], model: 'm' });
    vi.mocked(db.getChunksByBook).mockResolvedValue(chunks);
    vi.mocked(db.getChunksSpoilerSafe).mockImplementation(async (_b, max) =>
      chunks.filter((c) => c.episodeIndex <= max),
    );
    vi.mocked(db.getEmbeddingsByIds).mockImplementation(async (ids) => embMap(ids));
  });

  it('retrieveRelevant ranks spoiler-safe chunks by similarity', async () => {
    const res = await retrieveRelevant('q', 'b', 2); // episodes 0..2 → chunks 1..3
    expect(res.map((r) => r.chunk.id)).toEqual([3, 2, 1]);
    expect(res.every((r) => !r.isCallback)).toBe(true);
  });

  it('retrieveRelevant respects topK', async () => {
    const res = await retrieveRelevant('q', 'b', 5, 2);
    expect(res.map((r) => r.chunk.id)).toEqual([4, 5]);
  });

  it('skips chunks that have no embedding yet', async () => {
    vi.mocked(db.getEmbeddingsByIds).mockImplementation(async (ids) =>
      embMap(ids.filter((id) => id !== 3)),
    );
    const res = await retrieveRelevant('q', 'b', 2);
    expect(res.map((r) => r.chunk.id)).toEqual([2, 1]);
  });

  it('retrieveCallbacks uses MMR to avoid near-duplicate chunks', async () => {
    // 4 and 5 are near-duplicates; 3 is slightly less relevant but points elsewhere.
    const mmrVectors: Record<number, number[]> = {
      3: [1, 0, 0.5],
      4: [1, 0.2, 0],
      5: [1, 0.25, 0],
    };
    vi.mocked(embedOne).mockResolvedValue({ embedding: [1, 0, 0], model: 'm' });
    vi.mocked(db.getChunksByBook).mockResolvedValue([3, 4, 5].map(mkChunk));
    vi.mocked(db.getEmbeddingsByIds).mockImplementation(async (ids) => {
      const m = new Map<number, ChunkEmbedding>();
      ids.forEach((id) => m.set(id, { chunkId: id, embedding: mmrVectors[id], model: 'm', createdAt: '' }));
      return m;
    });

    const res = await retrieveCallbacks('q', 'b', 2);
    // Pure relevance order would be [4, 5]; MMR swaps the duplicate for the diverse chunk.
    expect(res.map((r) => r.chunk.id)).toEqual([4, 3]);
    expect(res.every((r) => r.isCallback)).toBe(true);
  });

  it('companionRetrieve never returns future chunks as relevant (spoiler invariant)', async () => {
    const ctx = await companionRetrieve('q', 'b', 1);
    expect(ctx.relevant.length).toBeGreaterThan(0);
    expect(ctx.relevant.every((r) => r.chunk.episodeIndex <= 1)).toBe(true);
    expect(ctx.callbacks.length).toBe(3);
    expect(embedOne).toHaveBeenCalledTimes(1);
  });

  it('companionRetrieve throws if storage ever leaks a future chunk', async () => {
    vi.mocked(db.getChunksSpoilerSafe).mockResolvedValue(chunks); // broken filter
    await expect(companionRetrieve('q', 'b', 0)).rejects.toThrow(/SPOILER VIOLATION/);
  });

  it('returns empty results when the book has no chunks', async () => {
    vi.mocked(db.getChunksByBook).mockResolvedValue([]);
    vi.mocked(db.getChunksSpoilerSafe).mockResolvedValue([]);
    expect(await companionRetrieve('q', 'b', 3)).toEqual({ relevant: [], callbacks: [] });
  });
});
