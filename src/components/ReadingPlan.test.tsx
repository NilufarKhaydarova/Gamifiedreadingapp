import { describe, it, expect, beforeEach } from 'vitest';
import { screen } from '@testing-library/react';
import { ReadingPlan } from './ReadingPlan';
import { renderAt, seedBook, isoDay } from '../test/utils';

describe('ReadingPlan', () => {
  beforeEach(() => localStorage.clear());

  it('shows an empty state without a book', () => {
    renderAt(<ReadingPlan />, '/plan');
    expect(screen.getByText(/No reading plan found/)).toBeInTheDocument();
  });

  it('shows book summary and one row per day with page ranges', () => {
    seedBook({ totalPages: 100 }, 10);
    renderAt(<ReadingPlan />, '/plan');

    expect(screen.getByText('Test Book')).toBeInTheDocument();
    expect(screen.getByText('10 days')).toBeInTheDocument();
    expect(screen.getAllByText(/^Day \d+$/)).toHaveLength(10);
    expect(screen.getByText('Pages 1 - 10')).toBeInTheDocument();
    expect(screen.getByText('Pages 91 - 100')).toBeInTheDocument();
  });

  it('marks the current day as Today', () => {
    seedBook({}, 10, { currentDay: 3 });
    renderAt(<ReadingPlan />, '/plan');
    const today = screen.getByText('Today');
    expect(today.parentElement).toHaveTextContent('Day 3');
  });

  it('shows a check mark for a day completed on its scheduled date', () => {
    // Uploaded today, day 1 completed today
    seedBook({}, 5, { completedDays: [isoDay(0)], currentDay: 2 });
    const { container } = renderAt(<ReadingPlan />, '/plan');
    expect(container.querySelectorAll('.lucide-circle-check').length).toBe(1);
  });

  it.fails('BUG: a day completed late is not shown as completed', () => {
    // Uploaded 2 days ago; reader missed a day and completed day 1 today.
    // Completion is matched by calendar date, so day 1 shows as not done.
    seedBook({ uploadDate: new Date(Date.now() - 2 * 864e5).toISOString() }, 5, {
      completedDays: [isoDay(0)],
      currentDay: 2,
    });
    renderAt(<ReadingPlan />, '/plan');
    const day1 = screen.getByText('Day 1').closest('div.flex.flex-col')!;
    expect(day1.querySelector('.lucide-circle-check')).not.toBeNull();
  });
});
