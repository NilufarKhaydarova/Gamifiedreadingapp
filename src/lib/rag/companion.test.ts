import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { askCompanion, fallbackResponse } from './companion';
import type { CompanionRetrievalContext } from './types';

const ctx: CompanionRetrievalContext = {
  relevant: [
    {
      chunk: {
        id: 1, bookId: 'b', chunkNumber: 0, episodeIndex: 0,
        episodeTitle: 'Chapter 1', content: 'It was a dark night.', startOffset: 0, endOffset: 20,
      },
      score: 0.9,
      isCallback: false,
    },
  ],
  callbacks: [],
};

describe('fallbackResponse', () => {
  it.each(['socratic', 'discussion', 'quiz'] as const)('mentions the book in %s mode', (mode) => {
    expect(fallbackResponse(mode, 'Dune')).toContain('"Dune"');
  });
});

describe('askCompanion', () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    vi.stubGlobal('fetch', fetchMock);
    fetchMock.mockReset();
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
  });

  it('throws a clear error when no API key is configured', async () => {
    vi.stubEnv('VITE_ANTHROPIC_API_KEY', '');
    await expect(
      askCompanion('hi', 'socratic', ctx, 'Dune', 'Herbert', 0, 5, []),
    ).rejects.toThrow(/VITE_ANTHROPIC_API_KEY not set/);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('sends history + retrieved context to the Messages API and returns the text', async () => {
    vi.stubEnv('VITE_ANTHROPIC_API_KEY', 'test-key');
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({ content: [{ type: 'text', text: 'What do you think?' }] }),
    });

    const reply = await askCompanion(
      'Why is it dark?', 'quiz', ctx, 'Dune', 'Herbert', 2, 10,
      [{ role: 'user', content: 'earlier' }, { role: 'assistant', content: 'reply' }],
    );

    expect(reply).toBe('What do you think?');
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://api.anthropic.com/v1/messages');
    expect(init.headers['x-api-key']).toBe('test-key');
    const body = JSON.parse(init.body);
    expect(body.messages).toEqual([
      { role: 'user', content: 'earlier' },
      { role: 'assistant', content: 'reply' },
      { role: 'user', content: 'Why is it dark?' },
    ]);
    expect(body.system).toContain('"Dune" by Herbert');
    expect(body.system).toContain('section 3 of 10');
    expect(body.system).toContain('It was a dark night.');
    expect(body.system).toContain('reading comprehension coach'); // quiz mode
  });

  it('surfaces API errors', async () => {
    vi.stubEnv('VITE_ANTHROPIC_API_KEY', 'test-key');
    fetchMock.mockResolvedValue({ ok: false, status: 401, text: async () => 'bad key' });
    await expect(
      askCompanion('hi', 'socratic', ctx, 'Dune', 'Herbert', 0, 5, []),
    ).rejects.toThrow(/401/);
  });
});
