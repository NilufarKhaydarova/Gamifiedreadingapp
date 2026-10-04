# Testing

## How to run

```bash
# Mobile app (Flutter)
cd booklify
flutter pub get
flutter test                 # whole suite (~15s)
flutter test --run-skipped   # also run the "known bug" tests (they fail)

# Web app
npm install                  # node_modules in git lacks jsdom/testing-library
npm test
```

The Flutter tests need **no API keys and no device**. They use:
- an in-memory/temporary SQLite DB via `sqflite_common_ffi`
- mocked `SharedPreferences`
- an empty `.env`, so every AI feature takes its offline fallback path

Tests marked `skip:` document **confirmed bugs**. Each skip reason starts with
`BUG:` and explains the bug. Once a bug is fixed, delete its `skip:` and the test
should pass.

## Latest results (2026-10-04)

| Suite | Pass | Known-bug (skipped) | Fail |
|---|---|---|---|
| Flutter (`booklify/test`) | 85 | 12 | 0 |
| Web (`src/**/*.test.*`) | 36 | 1 (stale test) | 0 |
| `dart analyze lib/` | 0 errors, 3 warnings, 82 infos | | |
| `npm run build` | ✓ | | |

## Test list — Flutter app

### Models (`test/models/`)
| Test | Status |
|---|---|
| Progress: percent, isCompleted, XP → level (100 XP/level) | ✅ |
| Progress: completeDay advances day, +50 XP, records date, clamps at last day | ✅ |
| Progress: JSON round-trip + defaults | ✅ |
| Progress: completing twice on the same day doesn't double the streak | 🐞 streak += 1 every call |
| Progress: finishing the last day sets `completedDate` | 🐞 never set → "books completed" always 0 |
| Book / BookChunk / SubChunk JSON round-trip, enum fallbacks, glossary | ✅ |
| Achievement unlock, JSON, unique ids; User JSON | ✅ |
| Curriculum: progress getters, lesson flags, step content, JSON, sparse AI JSON | ✅ |

### Services (`test/services/`)
| Test | Status |
|---|---|
| Chunker: empty input, chapter split, grouping, paragraph fallback, difficulty | ✅ |
| Chunker: keeps preface text before "Chapter 1" | 🐞 preface is dropped |
| Catalog: unique titles, valid metadata, genres, case-insensitive search | ✅ |
| AI provider: "No AI configured" without keys; topic-tag extraction | ✅ |
| Local RAG: finds matching episodes, **never leaks future days**, callbacks | ✅ |
| Curriculum fallback: locked structure, every topic family, lesson content, passage quizzes | ✅ |
| Curriculum fallback: "History of Spain" doesn't get the AI curriculum | 🐞 `contains('ai')` matches Sp**ai**n, br**ai**n… |
| DB schema: all 12 tables, 8 seeded achievements, version 3 | ✅ |
| DB migration v1 → v3 adds curricula + adaptive tables | ✅ |
| Auth: sign up/in/out, e-mail case-insensitive, duplicate e-mail, wrong password, demo account | ✅ |
| Books: save, list newest-first, update chunks, delete, per-user isolation, corrupt JSON | ✅ |
| Progress persistence, achievements unlock once, speed_reader after 5 sessions | ✅ |
| Daily challenge creation + minutes accumulation | ✅ |
| Streak: 0 with no sessions; 3 consecutive days | ✅ |
| Streak: a skipped day breaks it / last read 2 days ago → 0 | 🐞 compares 24h spans, not calendar days |
| Curriculum persistence, highlights, AI interactions, analytics, reader profile, insights | ✅ |

### Providers (`test/providers/`)
| Test | Status |
|---|---|
| Auth: starts logged out, sign-up survives restart, bad credentials error, sign-out | ✅ |
| Auth: `clearError()` clears the message | 🐞 `copyWith` can't set null |
| UserStats: first session, 200 XP/day cap, cap reset, streak continue/reset, achievements, persistence | ✅ |
| Curriculum: generate + reload, complete lesson → XP + unlock next, level unlock, from-book, reset | ✅ |
| Curriculum: replaying a finished lesson doesn't give XP again | 🐞 XP farmable (50 → 200 in test) |
| Books: add → 7-day offline plan, finish all chunks → book finished, remove | ✅ |
| Books: chunk offsets match the text | 🐞 drift by 2 chars/day (only affects offset fallback) |
| A book added in Library is seen by Home | 🐞 two different `booksProvider`s |

### UI (`test/widgets/`, real app, iPhone-sized 390 × 844)
| Test | Status |
|---|---|
| Onboarding → Skip → demo login → Learn/Books/Insights/Profile tabs render without errors | ✅ |
| Wrong password shows error and stays on login | ✅ |
| Login screen has no overflow | 🐞 demo-hint row overflows by ~53px |
| Sign out returns to onboarding | 🐞 user stays on main screen |
| ARB key parity en/ru/uz; localizations load for each locale | ✅ |

## Test list — Web app
| Test | Status |
|---|---|
| `storage.test.ts` (21 tests): books, profile, progress, XP, recommendations | ✅ |
| `Dashboard.test.tsx` (15 tests): empty state, book info, progress, completion | ✅ |
| Dashboard "Log Reading Session" card | ⏭ skipped: card was never in `Dashboard.tsx` |

## Not covered (manual testing needed)
These need real API keys, a device or platform plugins:
- Live Claude / Gemini / OpenAI calls (curriculum, lesson content, quizzes, Socratic chat, embeddings)
- File import (PDF/EPUB via `file_picker`), TTS / speech-to-text, audio
- Reading session screen paging and highlights UI, garden animation
- iOS / Android builds
