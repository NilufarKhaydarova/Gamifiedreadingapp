# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on iOS simulator
flutter run

# Build iOS simulator (verify compilation without launching)
flutter build ios --simulator

# Analyze Dart code
dart analyze lib/

# Analyze specific files
dart analyze lib/presentation/screens/reading/reading_session_screen.dart

# After editing ARB files (lib/l10n/app_*.arb), regenerate localizations
flutter pub get   # triggers code generation via l10n.yaml

# After adding packages or changing pubspec.yaml
flutter pub get

# Clean build artifacts (required when Xcode shows stale module errors)
flutter clean
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 RUBYOPT="-E utf-8" pod install  # run from ios/

# Full clean + rebuild cycle
flutter clean && flutter pub get && flutter build ios --simulator

# Code generation (after modifying @freezed/@riverpod models)
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### State Management — Riverpod 3.x
All providers live in `lib/presentation/providers/`. The project uses **Riverpod 3.x** (not 2.x):
- Use `Notifier<T>` + `NotifierProvider` (not `StateNotifier`/`StateNotifierProvider` — removed in 3.x)
- Use `StateProvider` replacement: `Notifier<T>` with a public setter method (e.g. `setBook(Book?)`)
- `AsyncValue.value` is nullable (was `.valueOrNull` in 2.x)
- Async initialization inside `Notifier.build()` must be deferred via `Future.microtask(fn)` if the method touches `state` synchronously before the first `await`

Key providers and their roles:
| Provider | Type | Purpose |
|---|---|---|
| `authProvider` | `NotifierProvider<AuthNotifier, AuthState>` | Auth state machine; init deferred via `Future.microtask` |
| `curriculumProvider` | `AsyncNotifierProvider<CurriculumNotifier, Curriculum?>` | AI-generated learning path |
| `booksProvider` | `AsyncNotifierProvider<BooksNotifier, List<Book>>` | User's book library |
| `currentBookProvider` | `NotifierProvider<CurrentBookNotifier, Book?>` | Active book selection; use `.notifier.setBook(book)` to update |
| `progressProvider` | `AsyncNotifierProvider<ProgressNotifier, Progress?>` | Reading progress for current book |
| `localeProvider` | `NotifierProvider<LocaleNotifier, Locale>` | App language, persisted via SharedPreferences |
| `userStatsProvider` | `AsyncNotifierProvider` | XP, level, achievements |

### Data Layer — SQLite (sqflite)
`DatabaseService` (`lib/data/services/database_service.dart`) is a singleton wrapping a local SQLite DB (`booklify.db`, version 3). All data is stored locally — no backend/Supabase in use. Tables: `users`, `books`, `reading_progress`, `highlights`, `ai_interactions`, `reading_analytics`, `curriculum`, `user_reading_profile`.

### AI Layer — Multi-provider with fallback chain

`AiProviderService` (`lib/data/services/ai_provider_service.dart`) orchestrates three AI backends with automatic fallback. API keys come from `assets/.env` loaded via `flutter_dotenv`. Models defined in `lib/core/constants/api_keys.dart`.

#### Claude (`lib/data/services/claude_service.dart`)
Direct REST via `Dio` → `api.anthropic.com/v1/messages`. Primary provider for all AI features.

| Method | Model | What it generates |
|---|---|---|
| `generateCurriculum()` | `claude-sonnet-4-5` | Full `Curriculum` JSON (levels → lessons → steps) from a topic or book |
| `loadLessonContent()` | `claude-sonnet-4-5` | Lazy step content: `read` pages, `quiz` MCQ list, `chat` first Socratic prompt |
| `chunkBook()` | `claude-haiku-4-5` | `BookChunk` array with `episodeTitle`, `keyIdea`, `estimatedMinutes`, `difficulty`, `glossary` |
| `generateReadingPlan()` | `claude-haiku-4-5` | Day-by-day reading schedule metadata |
| `generateQuiz()` | `claude-haiku-4-5` | MCQ questions for a passage |
| `socraticChat()` | `claude-haiku-4-5` | Next Socratic question in a reflection conversation |
| `analyzeKnowledgeGaps()` | `claude-sonnet-4-5` | Gap analysis from highlights + interactions |
| `generateReadingInsights()` | `claude-sonnet-4-5` | Personalised insight bullets for Insights tab |

#### Gemini (`lib/data/services/gemini_service.dart`)
Direct REST via `Dio` → `generativelanguage.googleapis.com/v1beta`. **Chat fallback only** — implements the same `socraticChat()` contract as Claude. Role mapping: `"assistant"` → `"model"` (Gemini's API requirement). Model: `gemini-2.0-flash`.

#### OpenAI (`lib/data/services/openai_service.dart`)
Direct REST via `Dio` → `api.openai.com/v1`. Two roles:
1. **Embeddings** (`text-embedding-3-small`): converts text to 1536-dim vectors for semantic RAG search (cosine similarity against chunk key ideas).
2. **Last-resort chat** (`gpt-4o-mini`): only reached if both Claude and Gemini fail for `socraticChat()`.

#### Adaptive RAG — `AdaptiveRagService` (`lib/data/services/adaptive_rag_service.dart`)
`buildContext(userId, currentChunk, lastQuestion?)` runs in parallel:
1. Fetches highlights, last 5 AI interactions, reading analytics, and reader profile from SQLite.
2. If `lastQuestion` is provided, calls OpenAI to embed it then computes cosine similarity against all `BookChunk.keyIdea` strings to find the most semantically relevant passage.
3. Assembles context as XML blocks injected into every AI system prompt:
   - `<current_passage>` — current chunk text + key idea
   - `<reader_highlights>` — user's saved highlights
   - `<ai_interaction_history>` — last 5 Q&A turns
   - `<reading_pace>` — avg WPM, preferred session length
   - `<semantically_relevant_passage>` — top cosine-similarity chunk (only if embedding succeeded)
   - `<reader_profile>` — persistent keyword/interest profile

`updateProfileAfterSession()` extracts keywords from new highlights and persists them back to the `user_reading_profile` SQLite table.

**Local RAG** (no API call): when OpenAI embedding fails or is unavailable, `AdaptiveRagService` falls back to keyword overlap between `lastQuestion` and chunk key ideas.

#### UI → AI call chain
```
InsightsScreen          → AiProviderService.generateReadingInsights()   (Claude sonnet)
InsightsScreen (chat)   → AiProviderService.socraticChat()              (Claude haiku → Gemini → OpenAI)
LessonScreen (quiz)     → CurriculumService.loadLessonContent()         (Claude sonnet)
LessonScreen (chat)     → AiProviderService.socraticChat()              (Claude haiku → Gemini → OpenAI)
AddBookSheet            → SmartChunkerService.createReadingPlan()       (Claude haiku for metadata)
CurriculumTab           → CurriculumService.generateCurriculum()        (Claude sonnet)
```
Every call that reaches Claude or Gemini first calls `AdaptiveRagService.buildContext()` to inject the XML user-context block into the system prompt.

### Book Chunking
`SmartChunkerService` splits uploaded text into `BookChunk`s (daily reading units). Each `BookChunk` contains `SubChunk`s and metadata: `keyIdea`, `episodeTitle`, `estimatedMinutes`, `difficulty`, `glossary`. PDF text is extracted via `syncfusion_flutter_pdf` and cleaned of page-header artifacts (`regex` strips `"Title\n61 of 967\n"` patterns).

### Curriculum System
`CurriculumService` uses Claude to generate a structured learning path from a topic or book. Structure: `Curriculum → CurriculumLevel[] → Lesson[] → LessonStep[]`. Steps are one of three types: `read` (paged text), `quiz` (AI-generated MCQ), `chat` (Socratic reflection). Step content is lazy-loaded via `loadLessonContent()`.

### Reading Experience
Both `ReadingSessionScreen` (books) and `LessonScreen._ReadStep` (lessons) use horizontal `PageView` for page-turn navigation. Text is paginated by paragraph budget (~1700–2200 chars/page depending on font size) via `_paginateText()`. Progress tracks `currentPage / (totalPages - 1)`.

### Localization
Three locales: `en`, `ru`, `uz`. ARB files in `lib/l10n/`. Generated class at `lib/l10n/app_localizations.dart` (output of `flutter pub get` with `generate: true` + `l10n.yaml`). Access pattern everywhere: `context.l10n.someKey` via the `AppLocalizationsX` extension in `lib/app.dart`.

### Navigation & App Shell
`_AuthGate` in `lib/app.dart` switches between `OnboardingScreen` and `MainScreen` based on `authStatusProvider`. `MainScreen` uses `IndexedStack` + `NavigationBar` with 4 tabs: Learn (curriculum map), Books (library), Insights (radar chart + concept columns), Profile.

### Gamification
`Progress` model: XP accumulates, `level = (xp ~/ 100) + 1`. Achievements defined in `lib/data/models/achievement.dart` (streak-based, speed-based). Session completion awards `(elapsedMinutes * 5) + 25` XP. Streak tracked via completed day timestamps.

### Theme
Single light theme only (`AppTheme.lightTheme`). Colors centralized in `lib/core/theme/app_colors.dart`. Use `.withValues(alpha: x)` not deprecated `.withOpacity(x)`.

## Common Tasks

### Adding a New Screen
1. Create screen file in appropriate `lib/presentation/screens/` subdirectory
2. Create provider in `lib/presentation/providers/` if state needed (use `Notifier<T>` pattern)
3. Add localized strings to ARB files in `lib/l10n/` and run `flutter pub get`

### Modifying Data Models
Models typically use `@freezed` annotation. After changes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Database Schema Changes
1. Increment version in `DatabaseService`
2. Add migration logic in `onUpgrade`
3. Test with existing data
