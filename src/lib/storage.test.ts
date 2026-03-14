import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  saveBook,
  getStoredBook,
  saveUserProfile,
  getUserProfile,
  initializeProgress,
  getProgress,
  updateProgress,
  clearAllData,
  addXP,
  getXPForNextLevel,
  getBookRecommendations,
  type Book,
  type Progress,
  type UserProfile,
} from './storage';

describe('Storage', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear();
    vi.clearAllMocks();
  });

  describe('Book storage', () => {
    it('should save and retrieve a book', () => {
      const book: Book = {
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 300,
        content: 'Test content',
        uploadDate: '2024-01-01',
      };

      saveBook(book);
      const retrieved = getStoredBook();

      expect(retrieved).toEqual(book);
    });

    it('should return null when no book is stored', () => {
      const retrieved = getStoredBook();
      expect(retrieved).toBeNull();
    });

    it('should overwrite existing book', () => {
      const book1: Book = {
        title: 'First Book',
        author: 'Author 1',
        totalPages: 200,
        content: 'Content 1',
        uploadDate: '2024-01-01',
      };

      const book2: Book = {
        title: 'Second Book',
        author: 'Author 2',
        totalPages: 400,
        content: 'Content 2',
        uploadDate: '2024-01-02',
      };

      saveBook(book1);
      saveBook(book2);
      const retrieved = getStoredBook();

      expect(retrieved).toEqual(book2);
    });
  });

  describe('User profile storage', () => {
    it('should save and retrieve user profile', () => {
      const profile: UserProfile = {
        age: 25,
        education: 'Bachelor',
        booksPerYear: 10,
        favoriteGenres: ['Fiction', 'Mystery'],
        onboardingComplete: true,
      };

      saveUserProfile(profile);
      const retrieved = getUserProfile();

      expect(retrieved).toEqual(profile);
    });

    it('should return null when no profile is stored', () => {
      const retrieved = getUserProfile();
      expect(retrieved).toBeNull();
    });
  });

  describe('Progress management', () => {
    it('should initialize progress with correct daily pages', () => {
      initializeProgress(300, 10);
      const progress = getProgress();

      expect(progress).not.toBeNull();
      expect(progress?.totalDays).toBe(10);
      expect(progress?.currentDay).toBe(1);
      expect(progress?.completedDays).toEqual([]);
      expect(progress?.xp).toBe(0);
      expect(progress?.level).toBe(1);
      expect(progress?.dailyPages).toHaveLength(10);
    });

    it('should distribute pages correctly across days', () => {
      initializeProgress(300, 10);
      const progress = getProgress();

      const firstDay = progress?.dailyPages[0];
      const lastDay = progress?.dailyPages[9];

      expect(firstDay?.start).toBe(1);
      expect(lastDay?.end).toBe(300);
    });

    it('should update progress', () => {
      initializeProgress(300, 10);
      let progress = getProgress();

      if (progress) {
        progress.currentDay = 2;
        progress.completedDays = ['2024-01-01'];
        updateProgress(progress);
      }

      const updated = getProgress();
      expect(updated?.currentDay).toBe(2);
      expect(updated?.completedDays).toContain('2024-01-01');
    });

    it('should return null when no progress exists', () => {
      const progress = getProgress();
      expect(progress).toBeNull();
    });
  });

  describe('Daily themes and summaries', () => {
    it('should generate appropriate themes for beginning of book', () => {
      initializeProgress(300, 10);
      const progress = getProgress();
      const firstDayTheme = progress?.dailyPages[0].theme;

      expect(firstDayTheme).toMatch(/Introduction|Setting|Characters|World|Conflicts|Context/);
    });

    it('should generate appropriate themes for end of book', () => {
      initializeProgress(300, 10);
      const progress = getProgress();
      const lastDayTheme = progress?.dailyPages[9].theme;

      expect(lastDayTheme).toMatch(/Resolution|Fates|Closing|Reflections|Conclusion/);
    });

    it('should generate summaries based on progress', () => {
      initializeProgress(300, 10);
      const progress = getProgress();

      const firstSummary = progress?.dailyPages[0].summary;
      const lastSummary = progress?.dailyPages[9].summary;

      expect(firstSummary).toContain('immersing');
      expect(lastSummary).toContain('conclude');
    });
  });

  describe('XP and leveling', () => {
    it('should add XP correctly', () => {
      initializeProgress(300, 10);
      addXP(50);

      const progress = getProgress();
      expect(progress?.xp).toBe(50);
    });

    it('should level up when enough XP is accumulated', () => {
      initializeProgress(300, 10);
      addXP(100); // Level 1 requires 100 XP

      const progress = getProgress();
      expect(progress?.level).toBe(2);
      expect(progress?.xp).toBe(0); // XP should reset after level up
    });

    it('should handle multiple level ups', () => {
      initializeProgress(300, 10);
      addXP(300); // Enough for level 1 (100) + level 2 (200) = 300 XP

      const progress = getProgress();
      expect(progress?.level).toBe(3);
    });

    it('should calculate XP needed for next level correctly', () => {
      expect(getXPForNextLevel(1)).toBe(100);
      expect(getXPForNextLevel(2)).toBe(200);
      expect(getXPForNextLevel(5)).toBe(500);
    });

    it('should not add XP when no progress exists', () => {
      // Should not throw error
      expect(() => addXP(50)).not.toThrow();
    });
  });

  describe('Clear all data', () => {
    it('should clear all stored data', () => {
      const book: Book = {
        title: 'Test',
        author: 'Author',
        totalPages: 100,
        content: 'Content',
        uploadDate: '2024-01-01',
      };

      const profile: UserProfile = {
        age: 25,
        education: 'Bachelor',
        booksPerYear: 10,
        favoriteGenres: ['Fiction'],
        onboardingComplete: true,
      };

      saveBook(book);
      saveUserProfile(profile);
      initializeProgress(100, 5);

      clearAllData();

      expect(getStoredBook()).toBeNull();
      expect(getUserProfile()).toBeNull();
      expect(getProgress()).toBeNull();
    });
  });

  describe('Book recommendations', () => {
    it('should recommend simpler books for casual readers', () => {
      const profile: UserProfile = {
        age: 25,
        education: 'Bachelor',
        booksPerYear: 3,
        favoriteGenres: ['Fiction'],
        onboardingComplete: true,
      };

      const recommendations = getBookRecommendations(profile);

      expect(recommendations).toContain('The Alchemist by Paulo Coelho');
      expect(recommendations).toContain('The Little Prince by Antoine de Saint-Exupéry');
    });

    it('should recommend moderate books for average readers', () => {
      const profile: UserProfile = {
        age: 30,
        education: 'Master',
        booksPerYear: 8,
        favoriteGenres: ['Fiction'],
        onboardingComplete: true,
      };

      const recommendations = getBookRecommendations(profile);

      expect(recommendations).toContain('1984 by George Orwell');
      expect(recommendations).toContain('To Kill a Mockingbird by Harper Lee');
    });

    it('should recommend complex books for avid readers', () => {
      const profile: UserProfile = {
        age: 35,
        education: 'PhD',
        booksPerYear: 20,
        favoriteGenres: ['Classic'],
        onboardingComplete: true,
      };

      const recommendations = getBookRecommendations(profile);

      expect(recommendations).toContain('War and Peace by Leo Tolstoy');
      expect(recommendations).toContain('Ulysses by James Joyce');
    });
  });
});
