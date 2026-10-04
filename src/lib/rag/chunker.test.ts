import { describe, it, expect } from 'vitest';
import { makeBookId, chunkText, episodeIndexFromProgress } from './chunker';

const words = (n: number, prefix = 'w') =>
  Array.from({ length: n }, (_, i) => `${prefix}${i}`).join(' ');

describe('makeBookId', () => {
  it('slugifies the title and appends the upload date', () => {
    expect(makeBookId('War & Peace!', '2024-03-05T10:00:00.000Z')).toBe('war_peace__20240305');
  });

  it('truncates long titles to 40 characters', () => {
    const id = makeBookId('a'.repeat(100), '2024-01-01T00:00:00Z');
    expect(id).toBe('a'.repeat(40) + '_20240101');
  });

  it('is stable for the same inputs', () => {
    expect(makeBookId('Dune', '2024-01-01')).toBe(makeBookId('Dune', '2024-01-01'));
  });
});

describe('chunkText', () => {
  it('returns no chunks for empty or whitespace-only text', () => {
    expect(chunkText('', 'b')).toEqual([]);
    expect(chunkText('   \n\t ', 'b')).toEqual([]);
  });

  it('returns a single chunk for short text', () => {
    const chunks = chunkText('Hello brave new world', 'b');
    expect(chunks).toHaveLength(1);
    expect(chunks[0]).toMatchObject({
      bookId: 'b',
      chunkNumber: 0,
      episodeIndex: 0,
      episodeTitle: 'Section 1',
      content: 'Hello brave new world',
      startOffset: 0,
    });
  });

  it('splits long text into ~500-word chunks with 50-word overlap', () => {
    const text = words(1200);
    const chunks = chunkText(text, 'b');
    // starts at word 0, 450, 900 → 3 chunks
    expect(chunks).toHaveLength(3);
    expect(chunks[0].content.split(' ')).toHaveLength(500);
    const first = chunks[0].content.split(' ');
    const second = chunks[1].content.split(' ');
    expect(second[0]).toBe('w450');
    expect(first.slice(-50)).toEqual(second.slice(0, 50));
    expect(chunks[2].content.split(' ').at(-1)).toBe('w1199');
  });

  it('numbers chunks sequentially and offsets map back to the source text', () => {
    const text = words(1000);
    const chunks = chunkText(text, 'b');
    chunks.forEach((c, i) => {
      expect(c.chunkNumber).toBe(i);
      expect(c.episodeIndex).toBe(i);
      expect(text.slice(c.startOffset, c.endOffset)).toBe(c.content);
    });
  });

  it('extracts chapter headings as episode titles', () => {
    const text = `Chapter 3\nThe storm arrived.\n${words(20)}`;
    expect(chunkText(text, 'b')[0].episodeTitle).toBe('Chapter 3');
  });

  it('recognises roman-numeral parts case-insensitively', () => {
    const text = `PART II\n${words(10)}`;
    expect(chunkText(text, 'b')[0].episodeTitle).toBe('PART II');
  });
});

describe('episodeIndexFromProgress', () => {
  const dailyPages = [
    { start: 1, end: 50 },
    { start: 51, end: 100 },
  ];

  it('returns 0 when there are no chunks or pages', () => {
    expect(episodeIndexFromProgress(1, dailyPages, 100, 0)).toBe(0);
    expect(episodeIndexFromProgress(1, dailyPages, 0, 10)).toBe(0);
  });

  it('maps the end page of the current day to a chunk index', () => {
    expect(episodeIndexFromProgress(1, dailyPages, 100, 11)).toBe(5);
    expect(episodeIndexFromProgress(2, dailyPages, 100, 11)).toBe(10);
  });

  it('falls back to the last chunk when the day is out of range', () => {
    expect(episodeIndexFromProgress(5, dailyPages, 100, 11)).toBe(10);
  });
});
