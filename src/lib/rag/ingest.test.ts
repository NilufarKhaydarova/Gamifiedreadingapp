import 'fake-indexeddb/auto';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { IDBFactory } from 'fake-indexeddb';

vi.mock('./embeddings', () => ({ embedBatch: vi.fn() }));

import { embedBatch } from './embeddings';
import { ingestBook } from './ingest';
import { closeDb, countChunks, getMissingEmbeddingIds, getChunksByBook } from './db';

const book = {
  title: 'Test Book',
  author: 'A',
  totalPages: 10,
  // 2000 words → chunks start at 0, 450, 900, 1350, 1800 → 5 chunks
  content: Array.from({ length: 2000 }, (_, i) => `w${i}`).join(' '),
  uploadDate: '2024-01-01T00:00:00.000Z',
};

describe('ingestBook', () => {
  beforeEach(() => {
    closeDb();
    globalThis.indexedDB = new IDBFactory();
    vi.mocked(embedBatch).mockReset();
    vi.mocked(embedBatch).mockImplementation(async (texts) => ({
      embeddings: texts.map(() => [1, 0]),
      model: 'test-model',
    }));
  });

  it('chunks, embeds and reports progress', async () => {
    const phases: string[] = [];
    const res = await ingestBook(book, (p) => phases.push(p.phase));

    expect(res).toEqual({ bookId: 'test_book_20240101', chunksTotal: 5, chunksEmbedded: 5 });
    expect(phases[0]).toBe('chunking');
    expect(phases).toContain('embedding');
    expect(phases.at(-1)).toBe('done');
    expect(await countChunks(res.bookId)).toBe(5);
  });

  it('embeds in batches of 8', async () => {
    const big = { ...book, content: Array.from({ length: 5000 }, (_, i) => `w${i}`).join(' ') };
    const res = await ingestBook(big);
    expect(res.chunksTotal).toBe(11);
    expect(vi.mocked(embedBatch).mock.calls.map((c) => c[0].length)).toEqual([8, 3]);
  });

  it('is idempotent: a second run embeds nothing new', async () => {
    await ingestBook(book);
    vi.mocked(embedBatch).mockClear();
    const res = await ingestBook(book);
    expect(res.chunksEmbedded).toBe(0);
    expect(embedBatch).not.toHaveBeenCalled();
  });

  it('skips failed batches so they can be retried later', async () => {
    vi.mocked(embedBatch).mockRejectedValueOnce(new Error('network'));
    vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await ingestBook(book);
    expect(res.chunksEmbedded).toBe(0);
    const ids = (await getChunksByBook(res.bookId)).map((c) => c.id!);
    expect(await getMissingEmbeddingIds(ids)).toHaveLength(5);

    const retry = await ingestBook(book);
    expect(retry.chunksEmbedded).toBe(5);
  });
});
