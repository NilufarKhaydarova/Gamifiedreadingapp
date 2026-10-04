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

  it('Play speaks the text, Pause pauses it', () => {
    seedBook();
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'play'));
    expect(synth.speak).toHaveBeenCalledTimes(1);
    expect(synth.speak.mock.calls[0][0].text).toContain('Once upon a time');

    fireEvent.click(iconButton(container, 'pause'));
    expect(synth.pause).toHaveBeenCalled();
  });

  it('skip forward saves the audio position', () => {
    seedBook();
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'skip-forward'));
    expect(getProgress()!.audioPosition).toBe(150);
  });

  it.fails("BUG: plays the whole book instead of only today's pages", () => {
    seedBook({ content: 'DAY-ONE-TEXT '.repeat(50) + 'LAST-DAY-TEXT' }, 10);
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'play'));
    expect(synth.speak.mock.calls[0][0].text).not.toContain('LAST-DAY-TEXT');
  });

  it.fails('BUG: skip / saved position does not change where playback starts', () => {
    seedBook({ content: 'START ' + 'x '.repeat(200) + 'LATER' }, 1);
    const { container } = renderAt(<AudioPlayer />, '/audio');
    fireEvent.click(iconButton(container, 'skip-forward'));
    fireEvent.click(iconButton(container, 'play'));
    expect(synth.speak.mock.calls[0][0].text.startsWith('START')).toBe(false);
  });
});
