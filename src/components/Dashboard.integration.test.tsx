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

  it.fails('BUG: XP shown on the dashboard does not update after marking a day complete', () => {
    seedBook({}, 10);
    renderAt(<Dashboard />);
    fireEvent.click(screen.getByRole('button', { name: /Mark Today's Reading Complete/i }));
    // Storage has 50 XP, but the component keeps its pre-XP copy of progress.
    expect(screen.getByText(/50 XP until Level 2/)).toBeInTheDocument();
  });

  it.fails('BUG: progress shows 100% before the final day is read', () => {
    // 10-day plan, 9 days done → currentDay 10, day 10 still unread.
    seedBook({}, 10, { currentDay: 10 });
    renderAt(<Dashboard />);
    expect(screen.queryByText(/100% Complete/)).not.toBeInTheDocument();
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
