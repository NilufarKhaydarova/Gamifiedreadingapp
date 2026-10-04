import { describe, it, expect, beforeEach, vi } from 'vitest';
import { screen, fireEvent, waitFor } from '@testing-library/react';

vi.mock('../lib/rag', async () => {
  const chunker = await vi.importActual<typeof import('../lib/rag/chunker')>('../lib/rag/chunker');
  const companion = await vi.importActual<typeof import('../lib/rag/companion')>('../lib/rag/companion');
  return {
    makeBookId: chunker.makeBookId,
    episodeIndexFromProgress: chunker.episodeIndexFromProgress,
    fallbackResponse: companion.fallbackResponse,
    companionRetrieve: vi.fn(),
    askCompanion: vi.fn(),
    countChunks: vi.fn(),
  };
});

import { companionRetrieve, askCompanion, countChunks } from '../lib/rag';
import { VoiceChatBot } from './VoiceChatBot';
import { renderAt, seedBook, mockSpeech, iconButton } from '../test/utils';

describe('VoiceChatBot (AI companion page)', () => {
  let synth: ReturnType<typeof mockSpeech>;

  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
    synth = mockSpeech();
    Element.prototype.scrollIntoView = vi.fn();
    vi.mocked(countChunks).mockResolvedValue(10);
    vi.mocked(companionRetrieve).mockResolvedValue({ relevant: [], callbacks: [] });
    vi.mocked(askCompanion).mockResolvedValue('Great question — what do you think?');
  });

  it('greets the reader in Book Club mode and reads the greeting aloud', () => {
    seedBook();
    renderAt(<VoiceChatBot />, '/chat');
    expect(screen.getByText(/Test Book/, { selector: 'p, div' })).toBeInTheDocument();
    expect(synth.speak).toHaveBeenCalledTimes(1);
  });

  it('sends a question with RAG context and shows the AI reply', async () => {
    seedBook({}, 10, { currentDay: 5 });
    renderAt(<VoiceChatBot />, '/chat');
    await waitFor(() => expect(countChunks).toHaveBeenCalled());

    const input = screen.getByPlaceholderText('Ask about Test Book…');
    fireEvent.change(input, { target: { value: 'Who is the hero?' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    expect(await screen.findByText('Great question — what do you think?')).toBeInTheDocument();
    expect(screen.getByText('Who is the hero?')).toBeInTheDocument();
    expect(companionRetrieve).toHaveBeenCalledWith('Who is the hero?', expect.stringMatching(/^test_book_\d{8}$/), 4);
    const [, mode, , title, author, episode, total, history] = vi.mocked(askCompanion).mock.calls[0];
    expect(mode).toBe('discussion');
    expect([title, author, total]).toEqual(['Test Book', 'Jane Writer', 10]);
    expect(episode).toBe(4); // day 5 of 10 → page 50/100 → chunk 4 of 0..9
    expect(history).toEqual([]);
  });

  it('falls back to a canned reply when the AI call fails (e.g. no API key)', async () => {
    vi.mocked(askCompanion).mockRejectedValue(new Error('VITE_ANTHROPIC_API_KEY not set'));
    vi.spyOn(console, 'error').mockImplementation(() => {});
    seedBook();
    renderAt(<VoiceChatBot />, '/chat');

    fireEvent.change(screen.getByPlaceholderText('Ask about Test Book…'), { target: { value: 'hi' } });
    fireEvent.keyDown(screen.getByPlaceholderText('Ask about Test Book…'), { key: 'Enter' });

    expect(await screen.findByText(/What connections are you making/)).toBeInTheDocument();
  });

  it('still answers when retrieval fails', async () => {
    vi.mocked(companionRetrieve).mockRejectedValue(new Error('no embeddings'));
    seedBook();
    renderAt(<VoiceChatBot />, '/chat');
    fireEvent.change(screen.getByPlaceholderText('Ask about Test Book…'), { target: { value: 'hi' } });
    fireEvent.keyDown(screen.getByPlaceholderText('Ask about Test Book…'), { key: 'Enter' });

    expect(await screen.findByText('Great question — what do you think?')).toBeInTheDocument();
    expect(vi.mocked(askCompanion).mock.calls[0][2]).toEqual({ relevant: [], callbacks: [] });
  });

  it('switching to Quiz mode resets the conversation with a quiz greeting', async () => {
    seedBook();
    renderAt(<VoiceChatBot />, '/chat');
    fireEvent.click(screen.getByText('Quiz'));
    expect(screen.getByText(/Welcome to Quiz Mode/)).toBeInTheDocument();

    fireEvent.change(screen.getByPlaceholderText('Ask about Test Book…'), { target: { value: 'go' } });
    fireEvent.keyDown(screen.getByPlaceholderText('Ask about Test Book…'), { key: 'Enter' });
    await screen.findByText('Great question — what do you think?');
    expect(vi.mocked(askCompanion).mock.calls[0][1]).toBe('quiz');
  });

  it('send button is disabled for empty input', () => {
    seedBook();
    const { container } = renderAt(<VoiceChatBot />, '/chat');
    expect(iconButton(container, 'send')).toBeDisabled();
  });

  it('warns when speech recognition is not supported', () => {
    const alert = vi.spyOn(window, 'alert').mockImplementation(() => {});
    seedBook();
    const { container } = renderAt(<VoiceChatBot />, '/chat');
    fireEvent.click(iconButton(container, 'mic'));
    expect(alert).toHaveBeenCalledWith(expect.stringMatching(/not supported/));
  });
});
