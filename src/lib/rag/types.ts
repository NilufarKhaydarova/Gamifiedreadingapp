// ─── RAG Core Types ───────────────────────────────────────────────────────────
// All RAG data lives in IndexedDB — no Supabase dependencies.

/** A contiguous slice of book text stored in IndexedDB. */
export interface BookChunk {
  id?: number;          // auto-increment primary key
  bookId: string;       // derived from book title + uploadDate
  chunkNumber: number;  // 0-based sequential index within the book
  episodeIndex: number; // same as chunkNumber (alias used for spoiler logic)
  episodeTitle: string; // e.g. "Section 3" or extracted heading
  content: string;      // raw text of this chunk (~500 words)
  startOffset: number;  // character offset in full book text
  endOffset: number;    // character offset (exclusive)
}

/** Embedding vector stored alongside its source chunk. */
export interface ChunkEmbedding {
  chunkId: number;       // FK → BookChunk.id
  embedding: number[];   // 1024 dims (Voyage) or 1536 dims (OpenAI fallback)
  model: string;         // e.g. "voyage-multilingual-2"
  createdAt: string;     // ISO timestamp
}

/** A chunk retrieved during a RAG query, with similarity score. */
export interface RetrievedChunk {
  chunk: BookChunk;
  score: number;       // cosine similarity ∈ [0, 1]
  isCallback: boolean; // true → cross-episode narrative callback (MMR path)
}

/** Complete retrieval context injected into the companion system prompt. */
export interface CompanionRetrievalContext {
  relevant: RetrievedChunk[];   // top-K spoiler-safe relevant chunks
  callbacks: RetrievedChunk[];  // cross-episode callbacks (MMR-diversified)
}
