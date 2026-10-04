# Test Plan

What is tested in both apps, how to run it, and the known bugs the tests found.

Last full run: 2026-10-04.

| Suite | Command | Result |
|---|---|---|
| Web: unit + component (Vitest) | `npm test` | 142 passed |
| Web: end-to-end in Chromium (Playwright) | `npm run test:e2e` | 2 passed |
| Web: production build | `npm run build` | OK |
| Flutter: unit + provider + widget | `cd booklify && flutter test` | 61 passed, 4 skipped (known bugs) |
| Flutter: static analysis | `cd booklify && dart analyze lib/` | 0 errors, 3 warnings, 82 infos |

**Known-bug tests.** A test named `BUG: ...` describes how the app *should* behave.
- Web (`it.fails`): passes while the bug exists and turns red once it is fixed. Then change `it.fails` to `it`.
- Flutter (`skip:`): skipped while the bug exists. Remove `skip:` after fixing.

## Running

```bash
# Web (repo root)
npm install
npm test                 # unit + component tests
npm run test:watch       # watch mode
npx playwright install chromium   # first time only
npm run test:e2e         # starts the dev server and runs the browser journey
npm run build

# Flutter
cd booklify
flutter pub get
flutter test
dart analyze lib/
```

No API keys are needed for any test. AI calls are mocked, or the app falls back to its offline replies.

---

## Web app (`src/`)

### Onboarding & access (`Onboarding.test.tsx`)
- [x] Continue stays disabled until age, education and books/year are filled in
- [x] Full flow saves the profile and opens Upload
- [x] Picking and un-picking genres
- [x] Recommendations match how much the user reads
- [x] Back returns to step 1
- [x] No profile → redirected to `/onboarding`; completed profile → page is shown
- [x] 0 books per year is accepted *(fixed)*; clearing the field disables Continue again

### Upload book (`UploadBook.test.tsx`)
- [x] Continue is disabled for empty or whitespace-only text
- [x] Paste text → details → book and reading plan are saved, RAG ingestion runs, user lands on the Dashboard
- [x] Uploading a `.txt` file opens the details step
- [x] Still finishes when ingestion fails (no API keys)
- [x] Shows ingestion progress ("Embedding passages: 1 / 4")
- [x] Back from details returns to the upload step
- [x] The page only advertises `.txt`, matching the file picker *(fixed: it used to claim .pdf/.epub)*

### Dashboard (`Dashboard.test.tsx`, `Dashboard.integration.test.tsx`)
- [x] Empty state and Upload button
- [x] Book info, level, XP, progress, streak, completed days, total pages
- [x] Today's pages, theme and summary
- [x] Mark today complete: saves the date, moves to the next day, +50 XP, button hides
- [x] Level up when XP passes the threshold
- [x] Streak of consecutive days ending today
- [x] Quick actions: AI Companion card; View Reading Plan card opens `/plan`
- [x] XP and level update right after marking a day complete *(fixed)*
- [x] Progress % is based on completed days, so it isn't 100% before the last day is read *(fixed)*
- [x] After marking complete, Today's Reading keeps showing the day just read, not tomorrow's *(fixed)*
- [x] A "finished the book" message replaces the button once every day is read *(fixed)*
- [x] The streak stays visible in the morning before today's reading *(fixed)*

### Reading plan (`ReadingPlan.test.tsx`)
- [x] Empty state
- [x] Book summary, one row per day, correct page ranges
- [x] Current day is marked "Today"
- [x] A day finished on its scheduled date shows a check mark
- [x] A day finished late (after a missed day) still shows as completed *(fixed)*
- [x] Once today is done, the next day says "Up next" instead of "Today" *(fixed)*

### AI companion chat (`VoiceChatBot.test.tsx`, `lib/rag/companion.test.ts`)
- [x] Welcome message for the book, read aloud
- [x] Question → RAG retrieval → Claude reply shown; the right mode, book and reading position are sent
- [x] AI failure (e.g. no API key) → offline fallback reply
- [x] Retrieval failure → still answers, with empty context
- [x] Switching mode resets the chat with that mode's greeting
- [x] Send is disabled for empty input; warning when speech recognition is unsupported
- [x] Claude request: API key header, history and user message, book/section/mode, retrieved passages in the system prompt
- [x] Clear error when no key is set; API errors are passed on

### Audio player (`AudioPlayer.test.tsx`)
- [x] Empty state
- [x] Shows the book and today's page range
- [x] Play speaks the text, Pause pauses it
- [x] Skip saves the position
- [x] Only today's pages are read aloud *(fixed: used to read the whole book)*
- [x] Skip moves playback (also while playing); Play starts from the saved position; reopening the page resumes *(fixed)*
- [x] Skip can't go before the start or past the end
- [x] Changing speed while playing keeps playing at the new rate *(fixed: it used to stop)*

### Achievements (`Achievements.test.tsx`)
- [x] Empty state; all 8 achievements listed
- [x] Streak achievements (7-day) and percentage achievements (25/50/75%) unlock
- [x] "Book Conqueror" unlocks only after the final day is read *(fixed)*

### Navigation (`Dashboard.integration.test.tsx`)
- [x] All 6 nav links render, the active one is highlighted, and clicking navigates

### Storage & gamification (`lib/storage.test.ts`)
- [x] Save and load the book, profile and progress; clear all data
- [x] Pages split across days, with the last day ending on the last page
- [x] Daily themes and summaries by position in the book
- [x] XP, level ups, multiple level ups, XP needed for the next level
- [x] Book recommendations by reading frequency
- [x] (`progress-helpers.test.ts`) Local-time dates, streak (today / yesterday / gaps / duplicates), completion %, the day's text split (no lost or repeated words), saving audio position without touching XP

### RAG library (`lib/rag/*.test.ts`)
- [x] `makeBookId` builds a stable slug from title and date
- [x] `chunkText`: empty input, ~500-word chunks with 50-word overlap, offsets map back to the source text, chapter / part headings become titles
- [x] `episodeIndexFromProgress` maps a reading day to a chunk index
- [x] IndexedDB: save / read / dedupe chunks, separate books, spoiler-safe query, save / overwrite embeddings, list missing embeddings
- [x] `cosineSimilarity` edge cases
- [x] Retrieval ranks only chunks up to the reader's position, respects top-K, skips chunks without embeddings
- [x] MMR callbacks avoid near-duplicate chunks
- [x] Spoiler guard throws if a future chunk ever leaks into results
- [x] Ingestion: chunk → embed in batches of 8 → progress events; running again embeds nothing new; failed batches are retried next run

### End-to-end in a real browser (`e2e/journey.spec.ts`)
- [x] New user: onboarding → upload → Dashboard → mark complete → plan (30 days) → chat (offline reply) → audio → achievements (1 of 8) → reload keeps data, with no JS errors
- [x] Returning user skips onboarding

---

## Flutter app (`booklify/`)

### Models (`test/models/models_test.dart`)
- [x] Progress: XP and levels (100 XP per level), completeDay (date, next day, streak, +50 XP), stops at the last day, JSON round-trip
- [x] Book / BookChunk / SubChunk JSON round-trip including glossary; unknown enum values fall back safely
- [x] User and Achievement JSON; achievement IDs are unique
- [x] Curriculum parsing of AI JSON with alternate keys (`book`/`author`/`color`, `correct` as a string, `chatPrompt`), progress counters, lesson progress, round-trip, bad colour fallback

### Book chunking (`test/services/chunker_service_test.dart`)
- [x] Empty book; one day per chapter; groups chapters when there are fewer days; never more days than chapters
- [x] Falls back to ~1000-word paragraph groups when there are no chapters
- [x] Each day gets a reading time and a preview; all chapter text is kept
- [ ] **BUG:** text before the first "Chapter" heading (preface, intro) is dropped
- [ ] **BUG:** books with Windows line endings (`\r\n`) end up as a single day
- [ ] **BUG:** `startOffset` / `endOffset` don't point at the chunk's text in the original book. The AI chat and curriculum use them to fetch the current passage, so the AI gets the wrong text.

### Local database (`test/services/database_service_test.dart`, real SQLite via FFI)
- [x] Sign up / sign out / sign in (email is case-insensitive), current user, duplicate email rejected, wrong password rejected, password is hashed
- [x] Books: save / list / update chunks / delete; each user only sees their own books
- [x] Progress: created once, saved and reloaded
- [x] 8 achievements seeded; unlocking happens only once
- [x] Daily challenge: 15-minute target, completes after enough reading
- [x] Reading sessions: minutes add up, streak counts
- [x] Curriculum save / load / delete; highlights and AI interactions per book; reader profile defaults and updates
- [ ] **BUG:** the streak keeps counting across a missed day (read today and 2 days ago → streak 2)

### Providers (`test/providers/providers_test.dart`)
- [x] UserStats: first session (XP, streak, First Steps), **200 XP daily cap**, cap resets the next day, consecutive days grow the streak, same day doesn't, a missed day resets it, achievements awarded once, book started / finished, survives a restart, corrupt data falls back to defaults, every awarded achievement is defined
- [x] Auth: starts logged out, sign up → in, sign out → out, sign in → in, saved session restored on launch, bad credentials → error message
- [x] Locale: English by default, switching persists, en/ru/uz offered
- [x] `clearError()` clears the message, and a successful sign-in clears an old error *(fixed)*
- [x] Error messages are shown without Dart's `Exception:` prefix *(fixed)*

### App smoke tests (`test/widgets/app_smoke_test.dart`)
- [x] Logged-out user sees onboarding
- [x] Logged-in user sees the main screen, and Learn / Books / Insights / Profile all open without crashing (no API keys)
- [x] A saved Russian language setting is applied to the navigation

---

## Other findings (not covered by a failing test)

- **Flutter: database achievements never unlock in the app.** `ProgressNotifier.completeDay()` (which calls `checkAndUnlockAchievements`) is never called from any screen. Reading sessions only update `userStatsProvider`, so the SQLite `user_achievements` table stays empty.
- **Flutter: achievement XP rewards are never granted.** Achievements define `xpReward`, but `UserStatsNotifier` doesn't add it.
- **Flutter: dates use UTC** (`toIso8601String().split('T')`) in places, so near midnight a day can be recorded under the wrong date. *(Fixed on web: it now uses local dates.)*
- **Flutter analyzer:** 3 warnings (2 unused imports in `book_provider.dart`, unused `_correctCount` in `lesson_screen.dart`) and 82 deprecation infos (mostly `withOpacity` → `withValues`).

## Not covered (manual testing)

- Live AI output quality (Claude / Gemini / OpenAI) with real keys
- PDF import (`syncfusion_flutter_pdf`) and iOS / Android device builds
- Speech recognition and text-to-speech on real devices
- How the reading-garden visuals look
