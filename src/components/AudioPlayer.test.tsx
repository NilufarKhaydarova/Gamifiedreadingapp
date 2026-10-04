import { describe, it, expect, beforeEach, vi } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { AudioPlayer } from './AudioPlayer';
import { getProgress } from '../lib/storage';
import { renderAt, seedBook, mockSpeech, iconButton } from '../test/utils';

describe('AudioPlayer', () => {
  let synth: ReturnType<typeof mockSpeech>;

  beforeEach(() => {
    localStorage.clear();
    synth = mockSpeech();
  });

  it('asks for a book when none is uploaded', () => {
    renderAt(<AudioPlayer />, '/audio');
    expect(screen.getByText(/upload a book first/)).toBeInTheDocument();
  });

  it("shows the book and today's page range", () => {
    seedBook({}, 10, { currentDay: 2 });
    renderAt(<AudioPlayer />, '/audio');
    expect(screen.getByText('Test Book')).toBeInTheDocument();
    expect(screen.getByText(/Day 2 - Pages 11 to 20/)).toBeInTheDocument();
  });

  // 10 pages, one word-marker per page: "P1 aaaa… P2 aaaa…"
  const pagedBook = (pages = 10) =>
    Array.from({ length: pages }, (_, i) => `P${i + 1} ${'a'.repeat(95)}`).join(' ');

  it('Play speaks the text, Pause pauses it', () => {
    seedBook({ content: pagedBook() }, 1);
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'play'));
    expect(synth.speak).toHaveBeenCalledTimes(1);
    expect(synth.speak.mock.calls[0][0].text).toContain('P1');

    fireEvent.click(iconButton(container, 'pause'));
    expect(synth.pause).toHaveBeenCalled();
  });

  it("plays only today's pages", () => {
    seedBook({ content: pagedBook(), totalPages: 10 }, 5, { currentDay: 2 }); // day 2 = pages 3–4
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'play'));
    const spoken: string = synth.speak.mock.calls[0][0].text;
    expect(spoken.startsWith('P3')).toBe(true);
    expect(spoken).toContain('P4');
    expect(spoken).not.toContain('P2 ');
    expect(spoken).not.toContain('P5');
  });

  it('skip forward saves the position and Play starts from there', () => {
    seedBook({ content: 'START ' + 'x '.repeat(200) + 'LATER' }, 1);
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'skip-forward'));
    expect(getProgress()!.audioPosition).toBe(150);

    fireEvent.click(iconButton(container, 'play'));
    const spoken: string = synth.speak.mock.calls[0][0].text;
    expect(spoken.startsWith('START')).toBe(false);
    expect(spoken).toContain('LATER');
  });

  it('skip while playing restarts speech at the new position', () => {
    seedBook({ content: 'START ' + 'x '.repeat(200) + 'LATER' }, 1);
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'play'));
    fireEvent.click(iconButton(container, 'skip-forward'));
    expect(synth.speak).toHaveBeenCalledTimes(2);
    expect(synth.speak.mock.calls[1][0].text.startsWith('START')).toBe(false);
  });

  it('skip back never goes below the start, skip forward never past the end', () => {
    seedBook({ content: 'short text here' }, 1);
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'skip-back'));
    expect(getProgress()!.audioPosition).toBe(0);
    fireEvent.click(iconButton(container, 'skip-forward'));
    expect(getProgress()!.audioPosition).toBe('short text here'.length);
  });

  it('resumes from the saved position after reopening the page', () => {
    seedBook({ content: 'START ' + 'x '.repeat(200) + 'LATER' }, 1, { audioPosition: 300 });
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'play'));
    expect(synth.speak.mock.calls[0][0].text.startsWith('START')).toBe(false);
  });

  it('changing speed while playing keeps playing at the new rate', () => {
    seedBook({ content: pagedBook() }, 1);
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'play'));
    fireEvent.click(iconButton(container, 'settings'));
    fireEvent.click(screen.getByRole('button', { name: '1.5x' }));
    expect(synth.speak).toHaveBeenCalledTimes(2);
    expect(synth.speak.mock.calls[1][0].rate).toBe(1.5);
  });
});
