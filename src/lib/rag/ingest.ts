// ─── Ingestion Pipeline ───────────────────────────────────────────────────────
// Called post-upload. Chunks book text, embeds in batches of 8, idempotent.

import { chunkText, makeBookId } from './chunker';
import { saveChunks, getMissingEmbeddingIds, getChunksByBook, saveEmbedding } from './db';
import { embedBatch } from './embeddings';
import type { Book } from '../storage';

const EMBED_BATCH_SIZE = 8;

export interface IngestProgress {
  phase: 'chunking' | 'embedding' | 'done';
  chunksTotal: number;
  chunksEmbedded: number;
}

type ProgressCallback = (p: IngestProgress) => void;

/**
 * Full ingestion pipeline for a book.
 *
 * 1. Derive bookId from title + uploadDate.
 * 2. Chunk the text (~500 words, 50-word overlap).
 * 3. Save chunks to IndexedDB (idempotent — skips existing).
 * 4. Embed missing chunks in batches of 8.
 * 5. Save embeddings to IndexedDB.
 *
 * Safe to call multiple times — already-embedded chunks are skipped.
 */
export async function ingestBook(
  book: Book,
  onProgress?: ProgressCallback,
): Promise<{ bookId: string; chunksTotal: number; chunksEmbedded: number }> {
  const bookId = makeBookId(book.title, book.uploadDate);

  // ── 1. Chunk ──────────────────────────────────────────────────────────────
  onProgress?.({ phase: 'chunking', chunksTotal: 0, chunksEmbedded: 0 });

  const rawChunks = chunkText(book.content, bookId);
  const ids = await saveChunks(rawChunks);
  const allChunks = await getChunksByBook(bookId);
  const chunksTotal = allChunks.length;

  // ── 2. Find missing embeddings ────────────────────────────────────────────
  const chunkIds = allChunks.map((c) => c.id!).filter(Boolean);
  const missingIds = await getMissingEmbeddingIds(chunkIds);

  if (missingIds.length === 0) {
    onProgress?.({ phase: 'done', chunksTotal, chunksEmbedded: 0 });
    return { bookId, chunksTotal, chunksEmbedded: 0 };
  }

  // ── 3. Embed in batches ───────────────────────────────────────────────────
  const missingChunks = allChunks.filter((c) => missingIds.includes(c.id!));
  let embedded = 0;

  for (let i = 0; i < missingChunks.length; i += EMBED_BATCH_SIZE) {
    const batch = missingChunks.slice(i, i + EMBED_BATCH_SIZE);
    const texts = batch.map((c) => c.content);

    onProgress?.({
      phase: 'embedding',
      chunksTotal,
      chunksEmbedded: embedded,
    });

    let result: { embeddings: number[][]; model: string };
    try {
      result = await embedBatch(texts);
    } catch (err) {
      console.error(`[RAG] Embedding batch ${i}–${i + batch.length} failed:`, err);
      continue; // skip this batch, will retry next ingest
    }

    for (let j = 0; j < batch.length; j++) {
      const chunk = batch[j];
      if (chunk.id == null) continue;
      await saveEmbedding({
        chunkId: chunk.id,
        embedding: result.embeddings[j],
        model: result.model,
        createdAt: new Date().toISOString(),
      });
      embedded++;
    }
  }

  onProgress?.({ phase: 'done', chunksTotal, chunksEmbedded: embedded });
  return { bookId, chunksTotal, chunksEmbedded: embedded };
}

/** Derive bookId without running ingestion (for retrieval). */
export { makeBookId };
