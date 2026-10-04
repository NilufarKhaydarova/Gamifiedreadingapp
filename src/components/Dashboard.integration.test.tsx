// Dashboard against real localStorage (Dashboard.test.tsx covers it with mocks).
import { describe, it, expect, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { Dashboard } from './Dashboard';
import { Root } from './Root';
import { getProgress } from '../lib/storage';
import { renderAt, seedBook, isoDay } from '../test/utils';
import { createMemoryRouter, RouterProvider } from 'react-router';
import { render } from '@testing-library/react';

describe('Dashboard (real storage)', () => {
  beforeEach(() => localStorage.clear());

  it('marking today complete saves progress, advances the day and awards 50 XP', () => {
    seedBook({}, 10);
    renderAt(<Dashboard />);
    fireEvent.click(screen.getByRole('button', { name: /Mark Today's Reading Complete/i }));

    const p = getProgress()!;
    expect(p.completedDays).toEqual([isoDay(0)]);
    expect(p.currentDay).toBe(2);
    expect(p.xp).toBe(50);
    expect(screen.queryByRole('button', { name: /Mark Today's Reading Complete/i })).not.toBeInTheDocument();
  });

  it('levels up after enough completed days', () => {
    seedBook({}, 10, { xp: 80 });
    renderAt(<Dashboard />);
    fireEvent.click(screen.getByRole('button', { name: /Mark Today's Reading Complete/i }));
    expect(getProgress()).toMatchObject({ level: 2, xp: 30 });
  });

  it('counts a streak of consecutive days ending today', () => {
    seedBook({}, 10, { completedDays: [isoDay(-2), isoDay(-1), isoDay(0)], currentDay: 4 });
    renderAt(<Dashboard />);
    expect(screen.getByText('Day Streak').previousElementSibling).toHaveTextContent('3');
  });

  it('XP on the dashboard updates right after marking a day complete', () => {
    seedBook({}, 10);
    renderAt(<Dashboard />);
    fireEvent.click(screen.getByRole('button', { name: /Mark Today's Reading Complete/i }));
    expect(screen.getByText(/50 XP until Level 2/)).toBeInTheDocument();
  });

  it('progress is not 100% until the final day is read', () => {
    // 10-day plan, 9 days done → currentDay 10, day 10 still unread.
    seedBook({}, 10, { currentDay: 10 });
    renderAt(<Dashboard />);
    expect(screen.queryByText(/100% Complete/)).not.toBeInTheDocument();
  });

  it("after marking complete, Today's Reading still shows the day just read", () => {
    seedBook({ totalPages: 100 }, 10);
    renderAt(<Dashboard />);
    expect(screen.getByText('Pages 1 - 10')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: /Mark Today's Reading Complete/i }));
    expect(screen.getByText('Pages 1 - 10')).toBeInTheDocument();
    expect(screen.getByText('Completed')).toBeInTheDocument();
  });

  it('shows the next day once a new day starts', () => {
    seedBook({ totalPages: 100 }, 10, { completedDays: [isoDay(-1)], currentDay: 2 });
    renderAt(<Dashboard />);
    expect(screen.getByText('Pages 11 - 20')).toBeInTheDocument();
    expect(screen.getByText('2/10')).toBeInTheDocument();
  });

  it('shows a finished message and no button once every day is read', () => {
    const done = Array.from({ length: 10 }, (_, i) => isoDay(-1 - i));
    seedBook({}, 10, { completedDays: done, currentDay: 10 });
    renderAt(<Dashboard />);
    expect(screen.getByText(/finished the book/)).toBeInTheDocument();
    expect(screen.getByText(/100% Complete/)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /Mark Today's Reading Complete/i })).not.toBeInTheDocument();
  });

  it('completing the final day shows the finished message right away', () => {
    const done = Array.from({ length: 9 }, (_, i) => isoDay(-1 - i));
    seedBook({}, 10, { completedDays: done, currentDay: 10 });
    renderAt(<Dashboard />);
    fireEvent.click(screen.getByRole('button', { name: /Mark Today's Reading Complete/i }));
    expect(screen.getByText(/finished the book/)).toBeInTheDocument();
    expect(screen.getByText(/100% Complete/)).toBeInTheDocument();
  });

  it('keeps the streak visible in the morning before reading', () => {
    seedBook({}, 10, { completedDays: [isoDay(-2), isoDay(-1)], currentDay: 3 });
    renderAt(<Dashboard />);
    expect(screen.getByText('Day Streak').previousElementSibling).toHaveTextContent('2');
  });
});

describe('Root navigation', () => {
  it('renders every nav item and highlights the active one', () => {
    const router = createMemoryRouter(
      [{ path: '/', element: <Root />, children: [{ path: '*', element: <div>child</div> }] }],
      { initialEntries: ['/plan'] },
    );
    render(<RouterProvider router={router} />);

    for (const label of ['Dashboard', 'Upload', 'Plan', 'Audio', 'Chat', 'Achievements']) {
      expect(screen.getByRole('link', { name: label })).toBeInTheDocument();
    }
    expect(screen.getByText('Plan')).toHaveClass('font-bold');
    expect(screen.getByText('Upload')).not.toHaveClass('font-bold');

    fireEvent.click(screen.getByRole('link', { name: 'Achievements' }));
    expect(router.state.location.pathname).toBe('/achievements');
  });
});
