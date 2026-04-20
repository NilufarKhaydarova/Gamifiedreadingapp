// ─── Text Chunker ─────────────────────────────────────────────────────────────
// Splits full book text into ~500-word overlapping chunks for RAG ingestion.

import type { BookChunk } from './types';

const TARGET_WORDS = 500;
const OVERLAP_WORDS = 50;

/** Derive a stable bookId from title + uploadDate. */
export function makeBookId(title: string, uploadDate: string): string {
  // Simple slug: lowercase alphanum + first 10 chars of ISO date
  return (
    title.toLowerCase().replace(/[^a-z0-9]+/g, '_').slice(0, 40) +
    '_' +
    uploadDate.slice(0, 10).replace(/-/g, '')
  );
}

/** Split text into word tokens, preserving character offsets. */
function tokenize(text: string): { word: string; start: number; end: number }[] {
  const tokens: { word: string; start: number; end: number }[] = [];
  const re = /\S+/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text)) !== null) {
    tokens.push({ word: m[0], start: m.index, end: m.index + m[0].length });
  }
  return tokens;
}

/**
 * Extract a section heading from chunk content.
 * Looks for lines that look like chapter/section headers:
 *  - "Chapter 3", "Part II", "Section 5", "CHAPTER ONE", etc.
 * Falls back to "Section N".
 */
function extractTitle(content: string, fallbackIndex: number): string {
  const lines = content.split('\n').map((l) => l.trim());
  const headingRe =
    /^(chapter|part|section|book|prologue|epilogue|act|scene)\s+[\divxlc]+/i;
  for (const line of lines.slice(0, 5)) {
    if (headingRe.test(line)) return line.slice(0, 60);
  }
  return `Section ${fallbackIndex + 1}`;
}

/**
 * Chunk book content into overlapping ~500-word segments.
 * Returns array of BookChunk (without `id`) ready to be saved to IndexedDB.
 */
export function chunkText(
  content: string,
  bookId: string,
): Omit<BookChunk, 'id'>[] {
  const tokens = tokenize(content);
  if (tokens.length === 0) return [];

  const chunks: Omit<BookChunk, 'id'>[] = [];
  let start = 0;

  while (start < tokens.length) {
    const end = Math.min(start + TARGET_WORDS, tokens.length);
    const startOffset = tokens[start].start;
    const endOffset = tokens[end - 1].end;
    const chunkContent = content.slice(startOffset, endOffset);

    const chunkIndex = chunks.length;
    chunks.push({
      bookId,
      chunkNumber: chunkIndex,
      episodeIndex: chunkIndex,
      episodeTitle: extractTitle(chunkContent, chunkIndex),
      content: chunkContent,
      startOffset,
      endOffset,
    });

    if (end >= tokens.length) break;
    // Advance by TARGET_WORDS - OVERLAP_WORDS for overlap
    start += TARGET_WORDS - OVERLAP_WORDS;
  }

  return chunks;
}

/**
 * Derive the current episode index from reading progress.
 * Maps the user's current page to the last chunk they've reached.
 */
export function episodeIndexFromProgress(
  currentDay: number,
  dailyPages: { start: number; end: number }[],
  totalPages: number,
  totalChunks: number,
): number {
  if (totalChunks === 0 || totalPages === 0) return 0;
  const dayData = dailyPages[Math.max(0, currentDay - 1)];
  if (!dayData) return totalChunks - 1;
  // Map page number to 0..1 fraction, then to chunk index
  const fraction = dayData.end / totalPages;
  return Math.floor(fraction * (totalChunks - 1));
}
