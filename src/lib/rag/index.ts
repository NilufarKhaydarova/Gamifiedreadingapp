// ─── RAG barrel export ────────────────────────────────────────────────────────
export type { BookChunk, ChunkEmbedding, RetrievedChunk, CompanionRetrievalContext } from './types';
export type { ChatMode, ConversationMessage } from './companion';
export type { IngestProgress } from './ingest';

export { makeBookId, chunkText, episodeIndexFromProgress } from './chunker';
export { ingestBook } from './ingest';
export { companionRetrieve, retrieveRelevant, retrieveCallbacks, cosineSimilarity } from './retrieve';
export { askCompanion, fallbackResponse } from './companion';
export { embedOne, embedBatch, resolveProvider } from './embeddings';
export { countChunks } from './db';
