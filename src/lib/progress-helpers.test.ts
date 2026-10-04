import { describe, it, expect, beforeEach } from 'vitest';
import {
  localDateISO,
  calculateStreak,
  getCompletionPercent,
  getDayText,
  saveAudioPosition,
  initializeProgress,
  getProgress,
  updateProgress,
  type Book,
  type Progress,
} from './storage';

const day = (offset: number, from = new Date(2024, 5, 15, 9)) => {
  const d = new Date(from);
  d.setDate(d.getDate() + offset);
  return localDateISO(d);
};

describe('localDateISO', () => {
  it('uses local calendar date, not UTC', () => {
    expect(localDateISO(new Date(2024, 0, 5, 23, 59))).toBe('2024-01-05');
    expect(localDateISO(new Date(2024, 11, 31, 0, 1))).toBe('2024-12-31');
  });
});

describe('calculateStreak', () => {
  const today = new Date(2024, 5, 15, 9);

  it('counts consecutive days ending today', () => {
    expect(calculateStreak([day(-2), day(-1), day(0)], today)).toBe(3);
  });

  it('keeps the streak alive before today is read', () => {
    expect(calculateStreak([day(-3), day(-2), day(-1)], today)).toBe(3);
  });

  it('is broken by a missed day', () => {
    expect(calculateStreak([day(-4), day(-3), day(-1), day(0)], today)).toBe(2);
    expect(calculateStreak([day(-3), day(-2)], today)).toBe(0);
  });

  it('ignores order and duplicates and does not modify the input', () => {
    const input = [day(0), day(-1), day(0)];
    expect(calculateStreak(input, today)).toBe(2);
    expect(input).toEqual([day(0), day(-1), day(0)]);
  });

  it('is 0 with no reading', () => {
    expect(calculateStreak([], today)).toBe(0);
  });
});

describe('getCompletionPercent', () => {
  const p = (completed: number, total = 10) =>
    ({ completedDays: Array(completed).fill('x'), totalDays: total }) as Progress;

  it('is based on completed days, not the current day', () => {
    expect(getCompletionPercent(p(0))).toBe(0);
    expect(getCompletionPercent(p(9))).toBe(90);
    expect(getCompletionPercent(p(10))).toBe(100);
  });

  it('never exceeds 100 and handles empty plans', () => {
    expect(getCompletionPercent(p(12))).toBe(100);
    expect(getCompletionPercent(p(0, 0))).toBe(0);
  });
});

describe('getDayText', () => {
  beforeEach(() => localStorage.clear());

  const words = Array.from({ length: 997 }, (_, i) => `w${i}`);
  const book = { content: words.join(' '), totalPages: 37 } as Book;

  it.each([1, 3, 7, 30])('splits the book into %i days with no lost or repeated words', (days) => {
    initializeProgress(book.totalPages, days);
    const parts = getProgress()!.dailyPages.map((d) => getDayText(book, d));
    expect(parts.join(' ').split(/\s+/)).toEqual(words);
  });

  it('returns the whole text when there is no page info', () => {
    expect(getDayText({ ...book, totalPages: 0 }, undefined)).toBe(book.content);
  });
});

describe('saveAudioPosition', () => {
  beforeEach(() => localStorage.clear());

  it('only changes the audio position', () => {
    initializeProgress(100, 10);
    updateProgress({ ...getProgress()!, xp: 70, level: 2 });
    saveAudioPosition(420);
    expect(getProgress()).toMatchObject({ audioPosition: 420, xp: 70, level: 2 });
  });
});
