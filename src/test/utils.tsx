import { render } from '@testing-library/react';
import { createMemoryRouter, RouterProvider, Outlet } from 'react-router';
import type { ReactElement } from 'react';
import { vi } from 'vitest';
import {
  saveBook,
  saveUserProfile,
  initializeProgress,
  getProgress,
  updateProgress,
  localDateISO,
  type Book,
  type Progress,
} from '../lib/storage';

/** Render `element` at `path` inside a memory router with stub pages for every app route. */
export function renderAt(element: ReactElement, path = '/') {
  const stub = (name: string) => <div data-testid={`page-${name}`}>{name} page</div>;
  const routes = [
    { path: '/onboarding', element: path === '/onboarding' ? element : stub('onboarding') },
    {
      path: '/',
      element: <Outlet />,
      children: [
        { index: true, element: path === '/' ? element : stub('dashboard') },
        ...['upload', 'plan', 'chat', 'achievements', 'audio'].map((p) => ({
          path: p,
          element: path === `/${p}` ? element : stub(p),
        })),
      ],
    },
  ];
  const router = createMemoryRouter(routes, { initialEntries: [path] });
  const utils = render(<RouterProvider router={router} />);
  return { router, ...utils };
}

export const isoDay = (offsetDays = 0) => {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  return localDateISO(d);
};

export function seedProfile() {
  saveUserProfile({
    age: 30,
    education: 'bachelors',
    booksPerYear: 10,
    favoriteGenres: ['Fiction'],
    onboardingComplete: true,
  });
}

export function seedBook(overrides: Partial<Book> = {}, days = 10, patch: Partial<Progress> = {}) {
  const book: Book = {
    title: 'Test Book',
    author: 'Jane Writer',
    totalPages: 100,
    content: 'Once upon a time there was a reader.',
    uploadDate: new Date().toISOString(),
    ...overrides,
  };
  saveBook(book);
  initializeProgress(book.totalPages, days);
  updateProgress({ ...getProgress()!, ...patch });
  return book;
}

/** Minimal Web Speech API stubs (jsdom has none). */
export function mockSpeech() {
  const synth = {
    speak: vi.fn(),
    cancel: vi.fn(),
    pause: vi.fn(),
    resume: vi.fn(),
    getVoices: vi.fn(() => []),
    paused: false,
    onvoiceschanged: null as unknown,
  };
  const Utterance = class {
    text: string;
    rate = 1;
    voice: unknown = null;
    onend: (() => void) | null = null;
    constructor(text: string) {
      this.text = text;
    }
  };
  // jsdom's window is not globalThis, so set both.
  for (const target of [window, globalThis] as Record<string, unknown>[]) {
    target.speechSynthesis = synth;
    target.SpeechSynthesisUtterance = Utterance;
  }
  return synth;
}

/** The (icon-only) button containing a lucide icon, e.g. iconButton(container, 'play'). */
export function iconButton(container: HTMLElement, icon: string) {
  const btn = container.querySelector(`.lucide-${icon}`)?.closest('button');
  if (!btn) throw new Error(`No button with icon "${icon}"`);
  return btn as HTMLButtonElement;
}
