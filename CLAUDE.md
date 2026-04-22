# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Monorepo Structure

This is a **monorepo** containing two applications:

1. **Web App** (root directory) — React/TypeScript with Vite
2. **Mobile App** (`booklify/` directory) — Flutter/Dart cross-platform app

The two apps share similar domain concepts (books, reading progress, gamification, AI features) but have separate implementations.

## Commands

### Web App (root directory)

```bash
# Development
npm run dev          # Start dev server on port 5173
npm run build        # Build for production (outputs to build/)

# Start scripts (uses Docker for some services)
./start.sh           # Start all services
./start.sh --web-only      # Start only web
./start.sh --with-langfuse # Start with Langfuse AI observability
npm run stop        # Stop all services
```

### Mobile App (`booklify/` directory)

```bash
cd booklify

# Dependency management
flutter pub get     # Install dependencies

# Running the app
flutter run         # Run on connected device/simulator
flutter build ios --simulator  # Build for iOS simulator
flutter build ios --release     # Build for iOS release
flutter build appbundle --release  # Build Android release bundle

# Code quality
dart analyze lib/   # Analyze Dart code
flutter clean       # Clean build artifacts

# Localization (after editing ARB files in lib/l10n/)
flutter pub get     # Regenerates app_localizations.dart

# Code generation (after modifying models with @freezed/@riverpod annotations)
dart run build_runner build --delete-conflicting-outputs

# Full clean + rebuild cycle
flutter clean && flutter pub get && flutter build ios --simulator
```

### iOS-specific (from `booklify/ios/`)

```bash
# After iOS-related changes or clean builds
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 RUBYOPT="-E utf-8" pod install
```

## Architecture Overview

### Web App Architecture

- **Framework**: React 18 with TypeScript, Vite 6.3.5
- **Routing**: React Router (declarative routes in `src/routes.ts`)
- **Styling**: Tailwind CSS with Radix UI components
- **State**: React hooks (useState, useEffect) + localStorage
- **Charts**: Recharts for visualizations

Key directories:
- `src/components/` — React components (Dashboard, UploadBook, etc.)
- `src/lib/` — Utilities, storage functions, API clients

### Mobile App Architecture

#### State Management — Riverpod 3.x
Uses `Notifier<T>` + `NotifierProvider` pattern (not StateNotifier, which was removed in Riverpod 3.x).

Key providers in `lib/presentation/providers/`:
| Provider | Type | Purpose |
|---|---|---|
| `authProvider` | `NotifierProvider<AuthNotifier, AuthState>` | Auth state machine |
| `curriculumProvider` | `AsyncNotifierProvider` | AI-generated learning paths |
| `booksProvider` | `AsyncNotifierProvider` | User's book library |
| `currentBookProvider` | `NotifierProvider` | Active book selection |
| `progressProvider` | `AsyncNotifierProvider` | Reading progress tracking |
| `localeProvider` | `NotifierProvider` | App language (en/ru/uz) |

#### Data Layer — SQLite (sqflite)
`DatabaseService` singleton manages local SQLite database (`booklify.db`, version 3). All data is local — no backend. Tables include: `users`, `books`, `reading_progress`, `highlights`, `ai_interactions`, `reading_analytics`, `curriculum`, `user_reading_profile`.

#### AI Layer — Multi-provider with Fallback
`AiProviderService` orchestrates three AI backends:

1. **Claude** (`lib/data/services/claude_service.dart`) — Primary provider via Dio REST API. Used for curriculum generation, lesson content, book chunking, quizzes, Socratic chat, knowledge gap analysis.
2. **Gemini** (`lib/data/services/gemini_service.dart`) — Chat fallback only (implements same `socraticChat()` contract)
3. **OpenAI** (`lib/data/services/openai_service.dart`) — Embeddings for RAG + last-resort chat fallback

**Adaptive RAG**: `AdaptiveRagService` builds XML context from highlights, AI interactions, reading analytics, and reader profile for injection into AI prompts.

#### Key Mobile Features
- **Book Chunking**: `SmartChunkerService` splits books into daily reading units with metadata (key idea, difficulty, glossary)
- **Curriculum System**: AI-generated structured learning paths (Curriculum → Levels → Lessons → Steps)
- **Reading Experience**: Horizontal `PageView` with text pagination by paragraph budget
- **Localization**: Three locales (en, ru, uz) via ARB files in `lib/l10n/`
- **Gamification**: XP system, leveling, achievements tracked via `Progress` model

#### Directory Structure
```
booklify/lib/
├── core/              # Constants, theme, utilities
├── data/              # Models, services (AI, DB, chunking)
├── presentation/      # Screens, providers, widgets
├── l10n/              # ARB localization files
├── widgets/           # Reusable widgets (e.g., garden visualization)
└── main.dart          # App entry point
```

## Important Patterns & Conventions

### Riverpod 3.x Specifics
- Use `Notifier<T>` with `build()` method, not `StateNotifier`
- Async initialization in `build()` must use `Future.microtask(fn)` if touching `state` before first `await`
- `AsyncValue.value` is nullable (was `.valueOrNull` in 2.x)
- Update state via public setter methods (e.g., `.notifier.setBook(book)`)

### Localization Pattern
```dart
// Access localized strings anywhere with BuildContext
context.l10n.someKey
```
Uses `AppLocalizationsX` extension from `lib/app.dart`.

### Theme
Single light theme only. Colors in `lib/core/theme/app_colors.dart`. Use `.withValues(alpha: x)` not deprecated `.withOpacity(x)`.

### Environment Variables
Flutter app loads API keys from `booklify/assets/.env` via `flutter_dotenv`. Never commit actual keys — use `.env.example` for documentation.

## Common Workflows

### Adding a New Screen (Flutter)
1. Create screen file in appropriate `lib/presentation/screens/` subdirectory
2. Add route to `go_router` configuration if navigation needed
3. Create provider in `lib/presentation/providers/` if state management needed
4. Add localized strings to ARB files in `lib/l10n/` and run `flutter pub get`

### Modifying Data Models
1. Update model class in `lib/data/models/` (typically uses `@freezed` annotation)
2. Run `dart run build_runner build --delete-conflicting-outputs` to generate code
3. Update `DatabaseService` schema version and migration logic if DB schema changed

### Working with AI Services
Go through `AiProviderService` — it handles fallback chain and RAG context injection automatically. Each AI call first calls `AdaptiveRagService.buildContext()` to inject XML user context.

## Testing

```bash
# Web app
npm test                # Run tests (if configured)

# Flutter app
flutter test            # Run unit/widget tests
```

## Troubleshooting

### iOS build issues
```bash
cd booklify
flutter clean
cd ios
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 RUBYOPT="-E utf-8" pod install
cd ..
flutter build ios --simulator
```

### Localization not updating
```bash
cd booklify
flutter pub get  # Regenerates app_localizations.dart from ARB files
```

### Code generation issues
```bash
cd booklify
dart run build_runner build --delete-conflicting-outputs
```
