// Local storage utilities for managing book data and progress

export interface Book {
  title: string;
  author: string;
  totalPages: number;
  content: string;
  uploadDate: string;
}

export interface DailyPage {
  start: number;
  end: number;
  pages: number;
  summary: string;
  theme: string;
}

export interface Progress {
  currentDay: number;
  totalDays: number;
  completedDays: string[]; // ISO date strings
  dailyPages: DailyPage[];
  xp: number;
  level: number;
  audioPosition: number;
}

export interface UserProfile {
  age: number;
  education: string;
  booksPerYear: number;
  favoriteGenres: string[];
  onboardingComplete: boolean;
}

const BOOK_KEY = 'booklify_book';
const PROGRESS_KEY = 'booklify_progress';
const PROFILE_KEY = 'booklify_profile';

export function saveBook(book: Book): void {
  localStorage.setItem(BOOK_KEY, JSON.stringify(book));
}

export function getStoredBook(): Book | null {
  const stored = localStorage.getItem(BOOK_KEY);
  return stored ? JSON.parse(stored) : null;
}

export function saveUserProfile(profile: UserProfile): void {
  localStorage.setItem(PROFILE_KEY, JSON.stringify(profile));
}

export function getUserProfile(): UserProfile | null {
  const stored = localStorage.getItem(PROFILE_KEY);
  return stored ? JSON.parse(stored) : null;
}

export function initializeProgress(totalPages: number, daysToComplete: number): void {
  const pagesPerDay = totalPages / daysToComplete;
  const dailyPages: DailyPage[] = [];

  let currentPage = 1;
  for (let i = 0; i < daysToComplete; i++) {
    const isLastDay = i === daysToComplete - 1;
    const endPage = isLastDay ? totalPages : Math.round(currentPage + pagesPerDay - 1);
    const dayNumber = i + 1;
    
    dailyPages.push({
      start: Math.round(currentPage),
      end: endPage,
      pages: endPage - Math.round(currentPage) + 1,
      summary: generateDailySummary(dayNumber, daysToComplete),
      theme: generateDailyTheme(dayNumber, daysToComplete),
    });

    currentPage = endPage + 1;
  }

  const progress: Progress = {
    currentDay: 1,
    totalDays: daysToComplete,
    completedDays: [],
    dailyPages,
    xp: 0,
    level: 1,
    audioPosition: 0,
  };

  localStorage.setItem(PROGRESS_KEY, JSON.stringify(progress));
}

function generateDailyTheme(dayNumber: number, totalDays: number): string {
  const progress = dayNumber / totalDays;
  
  if (progress <= 0.1) {
    const themes = [
      'Introduction & Setting',
      'Meet the Characters',
      'The World Unfolds',
      'Initial Conflicts',
      'Establishing Context'
    ];
    return themes[dayNumber % themes.length];
  } else if (progress <= 0.25) {
    const themes = [
      'Character Development',
      'Rising Tension',
      'Plot Foundations',
      'Key Relationships',
      'Emerging Themes'
    ];
    return themes[dayNumber % themes.length];
  } else if (progress <= 0.5) {
    const themes = [
      'Deepening Conflicts',
      'Character Motivations',
      'Plot Complications',
      'Thematic Exploration',
      'Turning Points'
    ];
    return themes[dayNumber % themes.length];
  } else if (progress <= 0.75) {
    const themes = [
      'Heightened Stakes',
      'Character Transformations',
      'Critical Moments',
      'Unraveling Mysteries',
      'Building Tension'
    ];
    return themes[dayNumber % themes.length];
  } else if (progress <= 0.9) {
    const themes = [
      'Approaching Climax',
      'Major Revelations',
      'Character Decisions',
      'Consequences Unfold',
      'Final Preparations'
    ];
    return themes[dayNumber % themes.length];
  } else {
    const themes = [
      'Resolution',
      'Character Fates',
      'Closing Themes',
      'Final Reflections',
      'Conclusion'
    ];
    return themes[dayNumber % themes.length];
  }
}

function generateDailySummary(dayNumber: number, totalDays: number): string {
  const progress = dayNumber / totalDays;
  
  if (progress <= 0.1) {
    return `Begin your journey by immersing yourself in the story's world. Focus on the setting, initial characters, and the narrative style.`;
  } else if (progress <= 0.25) {
    return `The foundation is being laid. Pay attention to character introductions, their relationships, and the emerging conflicts that will drive the story.`;
  } else if (progress <= 0.5) {
    return `The plot thickens as complexities emerge. Notice how characters evolve and themes develop through their actions and decisions.`;
  } else if (progress <= 0.75) {
    return `Tensions rise as the story reaches critical turning points. Observe how earlier events connect to current developments.`;
  } else if (progress <= 0.9) {
    return `The narrative builds toward its climax. Watch for pivotal moments and how conflicts move toward resolution.`;
  } else {
    return `The journey concludes. Reflect on character arcs, themes, and how the various narrative threads come together.`;
  }
}

export function getProgress(): Progress | null {
  const stored = localStorage.getItem(PROGRESS_KEY);
  return stored ? JSON.parse(stored) : null;
}

export function updateProgress(progress: Progress): void {
  localStorage.setItem(PROGRESS_KEY, JSON.stringify(progress));
}

export function clearAllData(): void {
  localStorage.removeItem(BOOK_KEY);
  localStorage.removeItem(PROGRESS_KEY);
  localStorage.removeItem(PROFILE_KEY);
}

// XP and leveling
export function addXP(amount: number): void {
  const progress = getProgress();
  if (!progress) return;

  progress.xp += amount;
  
  // Level up calculation: Each level requires 100 * level XP
  while (progress.xp >= progress.level * 100) {
    progress.xp -= progress.level * 100;
    progress.level++;
  }

  updateProgress(progress);
}

export function getXPForNextLevel(currentLevel: number): number {
  return currentLevel * 100;
}

export function getBookRecommendations(profile: UserProfile): string[] {
  // Generate book recommendations based on user profile
  const recommendations: string[] = [];

  if (profile.booksPerYear < 5) {
    recommendations.push(
      'The Alchemist by Paulo Coelho',
      'The Little Prince by Antoine de Saint-Exupéry',
      'Animal Farm by George Orwell'
    );
  } else if (profile.booksPerYear < 12) {
    recommendations.push(
      '1984 by George Orwell',
      'To Kill a Mockingbird by Harper Lee',
      'The Great Gatsby by F. Scott Fitzgerald'
    );
  } else {
    recommendations.push(
      'War and Peace by Leo Tolstoy',
      'Ulysses by James Joyce',
      'In Search of Lost Time by Marcel Proust'
    );
  }

  return recommendations;
}
// ── Shared progress helpers ───────────────────────────────────────────────────

/** YYYY-MM-DD in the user's local time zone (toISOString() would give UTC). */
export function localDateISO(date: Date = new Date()): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Consecutive reading days ending today — or yesterday, so the streak is not
 * shown as broken before today's reading is done.
 */
export function calculateStreak(completedDays: string[], today: Date = new Date()): number {
  const days = new Set(completedDays);
  const cursor = new Date(today);
  if (!days.has(localDateISO(cursor))) cursor.setDate(cursor.getDate() - 1);

  let streak = 0;
  while (days.has(localDateISO(cursor))) {
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

/** Percentage of plan days actually completed (0–100). */
export function getCompletionPercent(progress: Progress): number {
  if (progress.totalDays <= 0) return 0;
  return Math.min(100, (progress.completedDays.length / progress.totalDays) * 100);
}

/** The part of the book text covered by one day's page range. */
export function getDayText(book: Book, day: DailyPage | undefined): string {
  const text = book.content || '';
  if (!day || !book.totalPages) return text;

  const charsPerPage = text.length / book.totalPages;

  // If a boundary falls mid-word, move it to the end of that word. Both edges
  // use the same rule, so consecutive days split the text with no gaps or overlap.
  const snap = (pos: number) => {
    if (pos <= 0) return 0;
    if (pos >= text.length) return text.length;
    if (/\s/.test(text[pos - 1]) || /\s/.test(text[pos])) return pos;
    const ws = text.slice(pos).search(/\s/);
    return ws === -1 ? text.length : pos + ws;
  };
  const start = snap(Math.floor((day.start - 1) * charsPerPage));
  const end = snap(Math.floor(day.end * charsPerPage));
  return text.slice(start, end).trim();
}

/** Save the audio position without overwriting other progress fields. */
export function saveAudioPosition(position: number): void {
  const progress = getProgress();
  if (progress) updateProgress({ ...progress, audioPosition: position });
}
