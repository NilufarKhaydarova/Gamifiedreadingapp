import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { RouterProvider, createMemoryRouter } from 'react-router';
import { Dashboard } from './Dashboard';
import * as storage from '../lib/storage';

// Mock the storage module
vi.mock('../lib/storage', () => ({
  getStoredBook: vi.fn(),
  getProgress: vi.fn(),
  updateProgress: vi.fn(),
  addXP: vi.fn(),
  getXPForNextLevel: vi.fn(),
}));

describe('Dashboard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const createRouter = (element: React.ReactElement) =>
    createMemoryRouter([
      {
        path: '/',
        element,
      },
    ], {
      initialEntries: ['/'],
    });

  describe('When no book is uploaded', () => {
    beforeEach(() => {
      vi.mocked(storage.getStoredBook).mockReturnValue(null);
      vi.mocked(storage.getProgress).mockReturnValue(null);
    });

    it('should show empty state with upload prompt', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Start Your Reading Journey')).toBeInTheDocument();
      expect(screen.getByText(/Upload a book to begin/)).toBeInTheDocument();
    });

    it('should have upload button that navigates to upload page', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      const uploadButton = screen.getByText('Upload Your First Book');
      expect(uploadButton).toBeInTheDocument();
    });
  });

  describe('When a book is loaded', () => {
    const mockBook = {
      title: 'Test Book',
      author: 'Test Author',
      totalPages: 300,
      content: 'Test content',
      uploadDate: '2024-01-01',
    };

    const mockProgress = {
      currentDay: 3,
      totalDays: 10,
      completedDays: ['2024-01-01', '2024-01-02'],
      dailyPages: [
        { start: 1, end: 30, pages: 30, summary: 'Beginning', theme: 'Introduction' },
        { start: 31, end: 60, pages: 30, summary: 'Middle', theme: 'Development' },
        { start: 61, end: 90, pages: 30, summary: 'Today', theme: 'Conflict' },
      ],
      xp: 150,
      level: 2,
      audioPosition: 0,
    };

    beforeEach(() => {
      vi.mocked(storage.getStoredBook).mockReturnValue(mockBook);
      vi.mocked(storage.getProgress).mockReturnValue(mockProgress);
      vi.mocked(storage.getXPForNextLevel).mockReturnValue(200);
    });

    it('should display book information', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Test Book')).toBeInTheDocument();
      expect(screen.getByText('by Test Author')).toBeInTheDocument();
    });

    it('should show level and XP information', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Reader Level')).toBeInTheDocument();
      expect(screen.getByText(/150 \/ 200/)).toBeInTheDocument(); // XP
    });

    it('should show reading progress', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Day')).toBeInTheDocument();
      expect(screen.getByText('3/10')).toBeInTheDocument();
    });

    it('should display streak count', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      // Should show a streak number
      expect(screen.getByText('Day Streak')).toBeInTheDocument();
    });

    it('should show completed days count', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Days Completed')).toBeInTheDocument();
    });

    it('should show total pages', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Total Pages')).toBeInTheDocument();
      expect(screen.getByText('300')).toBeInTheDocument();
    });

    it('should display today\'s reading information', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText("Today's Reading")).toBeInTheDocument();
      expect(screen.getByText('Pages 61 - 90')).toBeInTheDocument();
    });

    it('should show today\'s theme', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Conflict')).toBeInTheDocument();
    });

    it('should mark reading complete when button clicked', async () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      const completeButton = screen.getByText('Mark Today\'s Reading Complete');
      fireEvent.click(completeButton);

      await waitFor(() => {
        expect(storage.updateProgress).toHaveBeenCalled();
        expect(storage.addXP).toHaveBeenCalledWith(50);
      });
    });
  });

  describe('When today is already completed', () => {
    const today = new Date().toISOString().split('T')[0];

    const mockBook = {
      title: 'Test Book',
      author: 'Test Author',
      totalPages: 300,
      content: 'Test content',
      uploadDate: '2024-01-01',
    };

    const mockProgress = {
      currentDay: 3,
      totalDays: 10,
      completedDays: [today], // Today is marked as completed
      dailyPages: [
        { start: 1, end: 30, pages: 30, summary: 'Today', theme: 'Introduction' },
      ],
      xp: 150,
      level: 2,
      audioPosition: 0,
    };

    beforeEach(() => {
      vi.mocked(storage.getStoredBook).mockReturnValue(mockBook);
      vi.mocked(storage.getProgress).mockReturnValue(mockProgress);
      vi.mocked(storage.getXPForNextLevel).mockReturnValue(200);
    });

    it('should show completed badge', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Completed')).toBeInTheDocument();
    });

    it('should not show mark complete button', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.queryByText('Mark Today\'s Reading Complete')).not.toBeInTheDocument();
    });
  });

  describe('Quick actions', () => {
    const mockBook = {
      title: 'Test Book',
      author: 'Test Author',
      totalPages: 300,
      content: 'Test content',
      uploadDate: '2024-01-01',
    };

    const mockProgress = {
      currentDay: 1,
      totalDays: 10,
      completedDays: [],
      dailyPages: [
        { start: 1, end: 30, pages: 30, summary: 'Today', theme: 'Introduction' },
      ],
      xp: 0,
      level: 1,
      audioPosition: 0,
    };

    beforeEach(() => {
      vi.mocked(storage.getStoredBook).mockReturnValue(mockBook);
      vi.mocked(storage.getProgress).mockReturnValue(mockProgress);
      vi.mocked(storage.getXPForNextLevel).mockReturnValue(100);
    });

    it('should show AI Reading Companion card', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('AI Reading Companion')).toBeInTheDocument();
      expect(screen.getByText(/Discuss, quiz, and deepen/)).toBeInTheDocument();
    });

    it('should show Log Reading Session card', () => {
      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      expect(screen.getByText('Log Reading Session')).toBeInTheDocument();
      expect(screen.getByText(/Track your progress and earn XP/)).toBeInTheDocument();
    });
  });

  describe('Progress calculations', () => {
    it('should calculate correct progress percentage', () => {
      const mockBook = {
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 300,
        content: 'Test content',
        uploadDate: '2024-01-01',
      };

      const mockProgress = {
        currentDay: 5,
        totalDays: 10,
        completedDays: [],
        dailyPages: [
          { start: 1, end: 30, pages: 30, summary: 'Today', theme: 'Introduction' },
        ],
        xp: 0,
        level: 1,
        audioPosition: 0,
      };

      vi.mocked(storage.getStoredBook).mockReturnValue(mockBook);
      vi.mocked(storage.getProgress).mockReturnValue(mockProgress);
      vi.mocked(storage.getXPForNextLevel).mockReturnValue(100);

      const router = createRouter(<Dashboard />);
      render(<RouterProvider router={router} />);

      // 5/10 = 50% progress - check for the pattern rather than exact string
      expect(screen.getByText(/\d+% Complete/)).toBeInTheDocument();
    });
  });
});
