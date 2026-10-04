import { describe, it, expect, beforeEach } from 'vitest';
import { screen } from '@testing-library/react';
import { Achievements } from './Achievements';
import { renderAt, seedBook, isoDay } from '../test/utils';

const lastNDays = (n: number) => Array.from({ length: n }, (_, i) => isoDay(-i));

describe('Achievements', () => {
  beforeEach(() => localStorage.clear());

  it('shows an empty state without progress', () => {
    renderAt(<Achievements />, '/achievements');
    expect(screen.getByText(/Start reading to unlock achievements/)).toBeInTheDocument();
  });

  it('lists all 8 achievements with nothing unlocked on a fresh plan', () => {
    seedBook({}, 30);
    renderAt(<Achievements />, '/achievements');
    expect(screen.getByText('0 of 8 unlocked')).toBeInTheDocument();
    ['First Steps', 'Week Warrior', 'Dedicated Reader', 'Unstoppable', 'Quarter Master',
      'Halfway Hero', 'Almost There', 'Book Conqueror'].forEach((t) =>
      expect(screen.getByText(t)).toBeInTheDocument(),
    );
  });

  it('unlocks First Steps and Week Warrior after a 7-day streak', () => {
    seedBook({}, 30, { completedDays: lastNDays(7), currentDay: 8 });
    renderAt(<Achievements />, '/achievements');
    // First Steps + Week Warrior (7/30 = 26.7% → Quarter Master too)
    expect(screen.getByText('3 of 8 unlocked')).toBeInTheDocument();
  });

  it('unlocks percentage achievements as the reader advances', () => {
    seedBook({}, 10, { completedDays: [isoDay(-30)], currentDay: 8 });
    renderAt(<Achievements />, '/achievements');
    // First Steps + 25% + 50% + 75%
    expect(screen.getByText('4 of 8 unlocked')).toBeInTheDocument();
  });

  it.fails('BUG: "Book Conqueror" unlocks before the final day is read', () => {
    // 10-day plan, days 1–9 completed → currentDay = 10, but day 10 not read yet.
    seedBook({}, 10, { completedDays: lastNDays(9).map((_, i) => isoDay(-40 - i)), currentDay: 10 });
    renderAt(<Achievements />, '/achievements');
    expect(screen.getByText('Book Conqueror')).not.toHaveTextContent('Unlocked');
  });
});
