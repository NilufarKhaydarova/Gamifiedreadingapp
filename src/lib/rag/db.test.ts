import 'fake-indexeddb/auto';
import { describe, it, expect, beforeEach } from 'vitest';
import { IDBFactory } from 'fake-indexeddb';
import {
  saveChunks,
  getChunksByBook,
  getChunksSpoilerSafe,
  countChunks,
  saveEmbedding,
  getEmbedding,
  getEmbeddingsByIds,
  getMissingEmbeddingIds,
  closeDb,
} from './db';
import type { BookChunk } from './types';

const chunk = (bookId: string, n: number): Omit<BookChunk, 'id'> => ({
  bookId,
  chunkNumber: n,
  episodeIndex: n,
  episodeTitle: `Section ${n + 1}`,
  content: `content ${n}`,
  startOffset: n * 10,
  endOffset: n * 10 + 9,
});

describe('RAG IndexedDB layer', () => {
  beforeEach(() => {
    closeDb();
    globalThis.indexedDB = new IDBFactory();
  });

  it('saves chunks and reads them back ordered by chunk number', async () => {
    await saveChunks([chunk('a', 2), chunk('a', 0), chunk('a', 1)]);
    const rows = await getChunksByBook('a');
    expect(rows.map((r) => r.chunkNumber)).toEqual([0, 1, 2]);
    expect(rows.every((r) => typeof r.id === 'number')).toBe(true);
  });

  it('is idempotent: re-saving the same chunks returns the same ids', async () => {
    const first = await saveChunks([chunk('a', 0), chunk('a', 1)]);
    const second = await saveChunks([chunk('a', 0), chunk('a', 1)]);
    expect(second).toEqual(first);
    expect(await countChunks('a')).toBe(2);
  });

  it('keeps books separate', async () => {
    await saveChunks([chunk('a', 0), chunk('b', 0), chunk('b', 1)]);
    expect(await countChunks('a')).toBe(1);
    expect(await countChunks('b')).toBe(2);
    expect(await countChunks('missing')).toBe(0);
  });

  it('spoiler-safe query only returns chunks up to the current episode', async () => {
    await saveChunks([0, 1, 2, 3, 4].map((n) => chunk('a', n)));
    const safe = await getChunksSpoilerSafe('a', 2);
    expect(safe.map((c) => c.episodeIndex)).toEqual([0, 1, 2]);
  });

  it('stores, overwrites and fetches embeddings', async () => {
    const [id] = await saveChunks([chunk('a', 0)]);
    expect(await getEmbedding(id)).toBeNull();

    await saveEmbedding({ chunkId: id, embedding: [1, 2], model: 'm1', createdAt: 'x' });
    await saveEmbedding({ chunkId: id, embedding: [3, 4], model: 'm2', createdAt: 'y' });

    const emb = await getEmbedding(id);
    expect(emb).toMatchObject({ embedding: [3, 4], model: 'm2' });
  });

  it('reports which chunks still need embeddings', async () => {
    const ids = await saveChunks([chunk('a', 0), chunk('a', 1), chunk('a', 2)]);
    await saveEmbedding({ chunkId: ids[1], embedding: [1], model: 'm', createdAt: 'x' });

    expect(await getMissingEmbeddingIds(ids)).toEqual([ids[0], ids[2]]);
    const map = await getEmbeddingsByIds(ids);
    expect([...map.keys()]).toEqual([ids[1]]);
  });
});
