# RAG Architecture — Socratic AI Companion

> Sprint 6 · Local-first vector retrieval with Claude Sonnet 4

---

## Overview

The Socratic AI Companion is a Retrieval-Augmented Generation (RAG) system that grounds Claude Sonnet 4 responses in actual passages from the user's uploaded book. All data — chunks, embeddings, conversation history — lives **entirely in the browser** (IndexedDB). No Supabase, no server, no round-trip for data storage.

```
Upload book
    │
    ▼
┌──────────┐    chunk (~500 words)    ┌────────────────┐
│ UploadBook│ ──────────────────────► │ IndexedDB       │
│ component │    embed (batches of 8) │  • chunks store │
└──────────┘ ──────────────────────► │  • embeddings   │
                                      └────────────────┘
                                             │
User sends message                           │
    │                                        │
    ▼                                        ▼
┌──────────────┐   embed query    ┌──────────────────────┐
│ ChatBot /     │ ──────────────► │  retrieve.ts          │
│ VoiceChatBot  │                 │  Path 1: top-K cosine │
└──────────────┘ ◄─────────────  │  Path 2: MMR callbacks│
    │            context          └──────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────┐
│ companion.ts — Claude Sonnet 4               │
│  system prompt with:                         │
│    <retrieved_context> (spoiler-safe)        │
│    <callbacks> (cross-episode, MMR)          │
└──────────────────────────────────────────────┘
```

---

## Storage Layer (`src/lib/rag/db.ts`)

**Database:** `booklify_rag` (IndexedDB, version 1)

### `chunks` object store

| Field          | Type     | Notes                                    |
|----------------|----------|------------------------------------------|
| `id`           | number   | auto-increment PK                        |
| `bookId`       | string   | `{slug}_{YYYYMMDD}` derived from title   |
| `chunkNumber`  | number   | 0-based sequential index                 |
| `episodeIndex` | number   | alias for chunkNumber, used in spoiler logic |
| `episodeTitle` | string   | extracted heading or "Section N"         |
| `content`      | string   | ~500 words of raw text                   |
| `startOffset`  | number   | character offset in full text            |
| `endOffset`    | number   | character offset (exclusive)             |

Indexes: `bookId`, `episodeIndex`, `(bookId, chunkNumber)` unique composite.

### `embeddings` object store

| Field       | Type       | Notes                              |
|-------------|------------|------------------------------------|
| `chunkId`   | number     | PK (= chunks.id)                   |
| `embedding` | number[]   | 1024 dims (Voyage) or 1536 (OpenAI)|
| `model`     | string     | e.g. `voyage-multilingual-2`       |
| `createdAt` | string     | ISO timestamp                      |

---

## Chunking (`src/lib/rag/chunker.ts`)

- Target: **~500 words** per chunk
- Overlap: **50 words** between adjacent chunks (for context continuity)
- Title extraction: scans first 5 lines for `Chapter/Part/Section` headings
- Idempotent: `saveChunks` skips existing `(bookId, chunkNumber)` pairs

---

## Embedding Generation (`src/lib/rag/embeddings.ts`)

| Priority | Provider | Model                    | Dims | Multilingual |
|----------|----------|--------------------------|------|--------------|
| 1st      | Voyage   | `voyage-multilingual-2`  | 1024 | ✅ en/ru/uz  |
| 2nd      | OpenAI   | `text-embedding-3-small` | 1536 | Partial      |

Provider selection order:
1. `VITE_RAG_EMBEDDING_PROVIDER` env var (if set)
2. Voyage if `VITE_VOYAGE_API_KEY` is present
3. OpenAI if `VITE_OPENAI_API_KEY` is present
4. Error if neither key exists

Batch size: **8 texts per API call** (matches Voyage rate limits).

---

## Retrieval (`src/lib/rag/retrieve.ts`)

### Path 1 — retrieve-to-question (spoiler-safe)

```
query → embed → cosine_similarity(query, chunk) for all chunks
     where chunk.episodeIndex ≤ currentEpisodeIndex    ← HARD FILTER
→ top-5 by score → injected as <retrieved_context>
```

**Spoiler invariant:** enforced at the `getChunksSpoilerSafe()` query level AND with a runtime assertion before injecting into the prompt. A violation throws, preventing the response.

### Path 2 — cross-episode callback retrieval (MMR)

```
query → embed → cosine_similarity(query, chunk) for ALL chunks
→ MMR selection (λ=0.5, top-3)
→ injected as <callbacks>
```

MMR (Maximal Marginal Relevance, λ=0.5):
```
score_mmr(d) = 0.5 · sim(d, query) - 0.5 · max_{s∈selected} sim(d, s)
```

Callbacks may reference later chapters. The companion system prompt instructs Claude to use them only as background awareness — never to paraphrase or quote their specific content if beyond the reader's current position.

---

## Companion (`src/lib/rag/companion.ts`)

**Model:** `claude-sonnet-4-5` via `https://api.anthropic.com/v1/messages`

**System prompt structure:**
```
You are an AI reading companion for "{title}" by {author}.
The reader is at section {N} of {total}.

{mode instructions: socratic | discussion | quiz}

CRITICAL RULE — SPOILER SAFETY: ...

<retrieved_context>
[Section 3 — Rising Action]
...text...
---
[Section 5 — Conflict]
...text...
</retrieved_context>

<callbacks>
[Section 12 — Resolution]
...text...
</callbacks>
```

**Modes:**
- `socratic` — Socratic tutor; asks probing questions, never gives answers
- `discussion` — Book club facilitator; warm discussion of themes/characters
- `quiz` — Reading comprehension coach; one question at a time with feedback

**Multilingual:** responds in the same language the reader uses.

---

## Ingestion Pipeline (`src/lib/rag/ingest.ts`)

Triggered automatically on book upload in `UploadBook.tsx`:

1. `chunkText(content, bookId)` → array of `BookChunk`
2. `saveChunks(chunks)` → idempotent, returns IDs
3. `getMissingEmbeddingIds(chunkIds)` → skip already-embedded
4. For each batch of 8 missing chunks:
   - `embedBatch(texts)` → `number[][]`
   - `saveEmbedding(...)` for each

Progress is surfaced via `IngestProgress` callbacks → shown as a progress bar in the UI.

---

## Spoiler Safety Test

The spoiler invariant is verified at two levels:

1. **Storage query:** `getChunksSpoilerSafe(bookId, maxEpisodeIndex)` only returns chunks with `episodeIndex ≤ maxEpisodeIndex`.
2. **Runtime assertion:** in `companionRetrieve()`, after retrieval, each `relevant` chunk is checked:
   ```typescript
   if (r.chunk.episodeIndex > currentEpisodeIndex) {
     throw new Error('SPOILER VIOLATION: ...');
   }
   ```

---

## Environment Variables

| Variable                    | Required | Description                              |
|-----------------------------|----------|------------------------------------------|
| `VITE_ANTHROPIC_API_KEY`    | ✅        | Claude Sonnet 4 companion                |
| `VITE_VOYAGE_API_KEY`       | ⚡ pref   | voyage-multilingual-2 embeddings         |
| `VITE_OPENAI_API_KEY`       | ⚡ fallbk | text-embedding-3-small fallback          |
| `VITE_RAG_EMBEDDING_PROVIDER` | ❌ opt  | Force `"voyage"` or `"openai"`          |
| `VITE_ENABLE_RAG_DEBUG`     | ❌ opt   | Enables console debug logging            |

---

## File Map

```
src/lib/rag/
  types.ts       TypeScript interfaces (BookChunk, RetrievedChunk, …)
  db.ts          IndexedDB CRUD layer
  chunker.ts     Text → BookChunk[] splitter
  embeddings.ts  Voyage / OpenAI embedding API wrappers
  ingest.ts      Full ingestion pipeline (chunk → embed → save)
  retrieve.ts    Cosine similarity + MMR retrieval
  companion.ts   Claude Sonnet 4 system prompt + API call
  index.ts       Barrel export
```

---

## Thesis Notes (Chapter 2)

Two retrieval contributions:

1. **Retrieve-to-question (R2Q):** standard dense retrieval but with a hard spoiler filter applied at query time — not as a post-hoc reranking step. This ensures grounding is epistemically honest: the AI only "knows" what the reader knows.

2. **Cross-episode callback retrieval (CECR):** MMR-diversified retrieval over the full corpus gives the AI background awareness of narrative callbacks without exposing them. The system prompt distinction between `<retrieved_context>` (reader-safe) and `<callbacks>` (AI-internal) is the key architectural novelty.
