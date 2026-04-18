// ─── IndexedDB Layer ──────────────────────────────────────────────────────────
// All RAG data (chunks + embeddings) persists here, replacing pgvector.

import type { BookChunk, ChunkEmbedding } from './types';

const DB_NAME = 'booklify_rag';
const DB_VERSION = 1;

let _db: IDBDatabase | null = null;

// ── Open / upgrade ────────────────────────────────────────────────────────────

function openDb(): Promise<IDBDatabase> {
  if (_db) return Promise.resolve(_db);

  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);

    req.onerror = () => reject(new Error(`IndexedDB open failed: ${req.error?.message}`));

    req.onsuccess = () => {
      _db = req.result;
      resolve(req.result);
    };

    req.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;

      // chunks store
      if (!db.objectStoreNames.contains('chunks')) {
        const store = db.createObjectStore('chunks', {
          keyPath: 'id',
          autoIncrement: true,
        });
        store.createIndex('bookId', 'bookId', { unique: false });
        store.createIndex('episodeIndex', 'episodeIndex', { unique: false });
        // composite unique: one chunk per (book, chunkNumber)
        store.createIndex('bookId_chunkNumber', ['bookId', 'chunkNumber'], {
          unique: true,
        });
      }

      // embeddings store — keyed by chunkId
      if (!db.objectStoreNames.contains('embeddings')) {
        db.createObjectStore('embeddings', { keyPath: 'chunkId' });
      }
    };
  });
}

// ── Generic helpers ───────────────────────────────────────────────────────────

function tx(
  db: IDBDatabase,
  storeName: string,
  mode: IDBTransactionMode,
): IDBObjectStore {
  return db.transaction(storeName, mode).objectStore(storeName);
}

function promisify<T>(req: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

function cursorAll<T>(index: IDBIndex | IDBObjectStore): Promise<T[]> {
  return new Promise((resolve, reject) => {
    const results: T[] = [];
    const req = index.openCursor();
    req.onsuccess = (e) => {
      const cursor = (e.target as IDBRequest<IDBCursorWithValue>).result;
      if (cursor) {
        results.push(cursor.value as T);
        cursor.continue();
      } else {
        resolve(results);
      }
    };
    req.onerror = () => reject(req.error);
  });
}

// ── Chunk CRUD ────────────────────────────────────────────────────────────────

/** Save a batch of chunks (idempotent — skips existing bookId+chunkNumber). */
export async function saveChunks(chunks: Omit<BookChunk, 'id'>[]): Promise<number[]> {
  const db = await openDb();
  const ids: number[] = [];

  for (const chunk of chunks) {
    const store = tx(db, 'chunks', 'readwrite');
    // Check existence via composite index
    const existing = await promisify<BookChunk | undefined>(
      store.index('bookId_chunkNumber').get([chunk.bookId, chunk.chunkNumber]),
    );
    if (existing?.id != null) {
      ids.push(existing.id);
      continue;
    }
    const id = await promisify<number>(
      tx(db, 'chunks', 'readwrite').add(chunk) as IDBRequest<number>,
    );
    ids.push(id);
  }

  return ids;
}

/** Fetch all chunks for a book, ordered by chunkNumber. */
export async function getChunksByBook(bookId: string): Promise<BookChunk[]> {
  const db = await openDb();
  const index = tx(db, 'chunks', 'readonly').index('bookId');
  const rows = await cursorAll<BookChunk>(index);
  return rows
    .filter((c) => c.bookId === bookId)
    .sort((a, b) => a.chunkNumber - b.chunkNumber);
}

/** Fetch all chunks with chunkNumber ≤ maxEpisodeIndex (spoiler-safe). */
export async function getChunksSpoilerSafe(
  bookId: string,
  maxEpisodeIndex: number,
): Promise<BookChunk[]> {
  const all = await getChunksByBook(bookId);
  return all.filter((c) => c.episodeIndex <= maxEpisodeIndex);
}

/** Count how many chunks exist for a book. */
export async function countChunks(bookId: string): Promise<number> {
  const all = await getChunksByBook(bookId);
  return all.length;
}

// ── Embedding CRUD ────────────────────────────────────────────────────────────

/** Store an embedding (overwrites if chunkId already exists). */
export async function saveEmbedding(emb: ChunkEmbedding): Promise<void> {
  const db = await openDb();
  await promisify(tx(db, 'embeddings', 'readwrite').put(emb));
}

/** Retrieve a single embedding by chunkId. */
export async function getEmbedding(chunkId: number): Promise<ChunkEmbedding | null> {
  const db = await openDb();
  const result = await promisify<ChunkEmbedding | undefined>(
    tx(db, 'embeddings', 'readonly').get(chunkId),
  );
  return result ?? null;
}

/** Retrieve all embeddings for a given list of chunk IDs. */
export async function getEmbeddingsByIds(
  chunkIds: number[],
): Promise<Map<number, ChunkEmbedding>> {
  const db = await openDb();
  const map = new Map<number, ChunkEmbedding>();
  for (const id of chunkIds) {
    const emb = await promisify<ChunkEmbedding | undefined>(
      tx(db, 'embeddings', 'readonly').get(id),
    );
    if (emb) map.set(id, emb);
  }
  return map;
}

/** Check how many of the given chunk IDs already have embeddings. */
export async function getMissingEmbeddingIds(chunkIds: number[]): Promise<number[]> {
  const db = await openDb();
  const missing: number[] = [];
  for (const id of chunkIds) {
    const emb = await promisify<ChunkEmbedding | undefined>(
      tx(db, 'embeddings', 'readonly').get(id),
    );
    if (!emb) missing.push(id);
  }
  return missing;
}

/** Close and invalidate the cached DB connection (used in tests / resets). */
export function closeDb(): void {
  _db?.close();
  _db = null;
}
