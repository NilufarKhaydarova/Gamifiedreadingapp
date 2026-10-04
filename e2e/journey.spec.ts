import { test, expect, type Page } from '@playwright/test';

// Full first-time user journey through the real app (no API keys needed:
// RAG ingestion and the AI companion fall back gracefully).

const BOOK_TEXT = Array.from({ length: 30 }, (_, i) => `Chapter ${i + 1}\nThe hero walked on.`).join('\n\n');

async function onboard(page: Page) {
  await page.goto('/');
  await expect(page).toHaveURL(/\/onboarding$/);
  await page.getByPlaceholder('Enter your age').fill('28');
  await page.getByRole('combobox').selectOption('bachelors');
  await page.getByPlaceholder('e.g., 12').fill('8');
  await page.getByRole('button', { name: 'Continue' }).click();
  await page.getByRole('button', { name: 'Fiction', exact: true }).click();
  await expect(page.getByText('1984 by George Orwell')).toBeVisible();
  await page.getByRole('button', { name: 'Get Started' }).click();
  await expect(page).toHaveURL(/\/upload$/);
}

async function uploadBook(page: Page) {
  await page.getByPlaceholder(/Paste the full text/).fill(BOOK_TEXT);
  await page.getByRole('button', { name: 'Continue' }).click();
  await page.getByPlaceholder('e.g., War and Peace').fill('The Long Walk');
  await page.getByPlaceholder('e.g., Leo Tolstoy').fill('A. Author');
  await page.getByPlaceholder('e.g., 1225').fill('300');
  await page.getByPlaceholder('e.g., 30').fill('30');
  await page.getByRole('button', { name: 'Create Reading Plan' }).click();
  await expect(page).toHaveURL(/\/$/, { timeout: 15_000 });
}

test('first-time user: onboarding → upload → read → plan → chat → audio → achievements', async ({ page }) => {
  const errors: string[] = [];
  page.on('pageerror', (e) => errors.push(e.message));

  await onboard(page);
  await uploadBook(page);

  // Dashboard
  await expect(page.getByText('The Long Walk')).toBeVisible();
  await expect(page.getByText('Pages 1 - 10')).toBeVisible();
  await page.getByRole('button', { name: /Mark Today's Reading Complete/ }).click();
  await expect(page.getByText('Completed', { exact: true })).toBeVisible();
  const stored = await page.evaluate(() => JSON.parse(localStorage.getItem('booklify_progress')!));
  expect(stored).toMatchObject({ currentDay: 2, xp: 50 });

  // Reading plan
  await page.getByRole('link', { name: 'Plan' }).click();
  await expect(page.getByText('Daily Reading Schedule')).toBeVisible();
  await expect(page.getByText(/^Day \d+$/)).toHaveCount(30);

  // AI companion (no key → fallback reply)
  await page.getByRole('link', { name: 'Chat' }).click();
  await expect(page.getByText(/The Long Walk/).first()).toBeVisible();
  const input = page.getByPlaceholder('Ask about The Long Walk…');
  await input.fill('Why does the hero keep walking?');
  await input.press('Enter');
  await expect(page.getByText('Why does the hero keep walking?')).toBeVisible();
  await expect(page.getByText(/What connections are you making/)).toBeVisible({ timeout: 15_000 });

  // Audio
  await page.getByRole('link', { name: 'Audio' }).click();
  await expect(page.getByText('Now Playing')).toBeVisible();
  await expect(page.getByText(/Day 2 - Pages 11 to 20/)).toBeVisible();

  // Achievements
  await page.getByRole('link', { name: 'Achievements' }).click();
  await expect(page.getByText('1 of 8 unlocked')).toBeVisible();

  // Data survives a reload
  await page.reload();
  await expect(page.getByText('1 of 8 unlocked')).toBeVisible();

  expect(errors).toEqual([]);
});

test('returning user goes straight to the dashboard', async ({ page }) => {
  await onboard(page);
  await page.goto('/');
  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByText('Start Your Reading Journey')).toBeVisible();
});
