import 'package:booklify/data/models/achievement.dart';
import 'package:booklify/data/models/book.dart';
import 'package:booklify/data/models/curriculum.dart';
import 'package:booklify/data/models/progress.dart';
import 'package:booklify/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

Progress _progress({int currentDay = 1, int totalDays = 10, int xp = 0}) =>
    Progress(
      id: 'p1',
      userId: 'u1',
      bookId: 'b1',
      currentDay: currentDay,
      totalDays: totalDays,
      xp: xp,
      level: xp ~/ 100 + 1,
    );

void main() {
  group('Progress', () {
    test('addXP levels up every 100 XP', () {
      final p = _progress().addXP(250);
      expect(p.xp, 250);
      expect(p.level, 3);
      expect(p.levelProgress, closeTo(0.5, 1e-9));
      expect(p.xpToNextLevel, 300);
    });

    test('completeDay records today, advances the day, adds streak and 50 XP', () {
      final p = _progress(currentDay: 3).completeDay();
      final today = DateTime.now().toIso8601String().split('T')[0];
      expect(p.completedDays, [today]);
      expect(p.currentDay, 4);
      expect(p.streakDays, 1);
      expect(p.xp, 50);
      expect(p.lastSessionDate, isNotNull);
    });

    test('completeDay never goes past the last day', () {
      final p = _progress(currentDay: 10, totalDays: 10).completeDay();
      expect(p.currentDay, 10);
      expect(p.isCompleted, isTrue);
    });

    test('progressPercent handles zero total days', () {
      expect(_progress(totalDays: 0).progressPercent, 0);
      expect(_progress(currentDay: 5, totalDays: 10).progressPercent, 0.5);
    });

    test('JSON round-trip keeps all fields', () {
      final p = _progress(currentDay: 2, xp: 120).completeDay();
      final back = Progress.fromJson(p.toJson());
      expect(back.toJson(), p.toJson());
    });
  });

  group('Book / BookChunk', () {
    test('JSON round-trip including chunks, sub-chunks and glossary', () {
      final book = Book(
        id: 'b1',
        title: 'Dune',
        author: 'Frank Herbert',
        totalPages: 600,
        content: 'Arrakis...',
        uploadDate: DateTime.utc(2024, 1, 2),
        genres: ['Sci-Fi'],
        chunks: [
          BookChunk(
            id: 'day-1',
            dayNumber: 1,
            episodeTitle: 'Chapter 1',
            keyIdea: 'Spice',
            preview: 'Arrakis',
            difficulty: Difficulty.dense,
            estimatedMinutes: 12,
            startOffset: 0,
            endOffset: 10,
            subChunks: [
              SubChunk(id: 's1', content: 'Arrakis...', type: ChunkType.chapter, wordCount: 1),
            ],
            glossary: {'Spice': 'Melange'},
          ),
        ],
      );
      final back = Book.fromJson(book.toJson());
      expect(back.toJson(), book.toJson());
      expect(back.chunks.single.glossary['Spice'], 'Melange');
      expect(back.chunks.single.subChunks.single.type, ChunkType.chapter);
    });

    test('unknown enum values fall back to safe defaults', () {
      final chunk = BookChunk.fromJson({
        'id': 'c',
        'dayNumber': 1,
        'episodeTitle': 't',
        'keyIdea': '',
        'preview': '',
        'difficulty': 'extreme',
        'estimatedMinutes': 5,
        'startOffset': 0,
        'endOffset': 1,
        'subChunks': [
          {'id': 's', 'content': 'x', 'type': 'weird'},
        ],
        'glossary': {'n': 42},
      });
      expect(chunk.difficulty, Difficulty.moderate);
      expect(chunk.subChunks.single.type, ChunkType.section);
      expect(chunk.glossary['n'], '42');
      expect(chunk.completed, isFalse);
    });
  });

  group('User', () {
    test('JSON round-trip', () {
      final u = User(
        id: 'u',
        email: 'a@b.c',
        displayName: 'Ann',
        favoriteGenres: ['Fiction'],
        createdAt: DateTime.utc(2024),
        onboardingComplete: true,
        preferredLanguage: 'uz',
      );
      expect(User.fromJson(u.toJson()).toJson(), u.toJson());
    });
  });

  group('Achievement', () {
    test('unlock sets unlockedAt', () {
      final a = Achievements.all.first;
      expect(a.isUnlocked, isFalse);
      expect(a.unlock().isUnlocked, isTrue);
    });

    test('predefined achievements have unique ids', () {
      final ids = Achievements.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('unknown category falls back to streak', () {
      final a = Achievement.fromJson({
        'id': 'x',
        'title': 't',
        'description': 'd',
        'iconUrl': 'i',
        'category': 'nope',
      });
      expect(a.category, AchievementCategory.streak);
    });
  });

  group('Curriculum (parsing AI output)', () {
    final aiJson = {
      'title': 'Learn Stoicism',
      'levels': [
        {
          'number': 1,
          'title': 'Foundations',
          'book': 'Meditations', // alternate key the AI sometimes uses
          'author': 'Marcus Aurelius',
          'color': '#FF0000',
          'lessons': [
            {
              'number': 1,
              'title': 'Control',
              'is_unlocked': true,
              'steps': [
                {'type': 'read', 'title': 'Intro', 'content': 'Text'},
                {
                  'type': 'quiz',
                  'title': 'Check',
                  'questions': [
                    {'question': 'Q?', 'options': ['a', 'b'], 'correct': '1'},
                  ],
                },
                {'type': 'chat', 'title': 'Talk', 'chatPrompt': 'Discuss'},
              ],
            },
            {'number': 2, 'title': 'Virtue', 'steps': []},
          ],
        },
      ],
    };

    test('parses levels, lessons, steps and quiz questions with alternate keys', () {
      final c = Curriculum.fromJson(aiJson, id: 'c1', userId: 'u1', topic: 'stoicism');
      final level = c.levels.single;
      expect(level.bookTitle, 'Meditations');
      expect(level.bookAuthor, 'Marcus Aurelius');
      expect(level.color.toARGB32(), 0xFFFF0000);

      final steps = level.lessons.first.steps;
      expect(steps.map((s) => s.type), [LessonStepType.read, LessonStepType.quiz, LessonStepType.chat]);
      expect(steps.every((s) => s.hasContent), isTrue);
      expect(steps[1].questions.single.correctIndex, 1);
      expect(steps[2].chatPrompt, 'Discuss');
    });

    test('progress counters', () {
      final c = Curriculum.fromJson(aiJson);
      expect(c.totalLessons, 2);
      expect(c.completedLessons, 0);
      expect(c.overallProgress, 0);
      expect(c.currentLevelNumber, 1);

      final lessons = c.levels.first.lessons.map((l) => l.copyWith(isCompleted: true)).toList();
      final done = c.copyWith(levels: [c.levels.first.copyWith(lessons: lessons)]);
      expect(done.overallProgress, 1);
      expect(done.levels.first.isCompleted, isTrue);
    });

    test('lesson progress and in-progress state', () {
      final lesson = Curriculum.fromJson(aiJson).levels.first.lessons.first;
      final steps = [lesson.steps[0].copyWith(isCompleted: true), ...lesson.steps.skip(1)];
      final updated = lesson.copyWith(steps: steps);
      expect(updated.progressPercent, closeTo(1 / 3, 1e-9));
      expect(updated.isInProgress, isTrue);
    });

    test('JSON round-trip', () {
      final c = Curriculum.fromJson(aiJson, id: 'c1', userId: 'u1', topic: 't',
          createdAt: DateTime.utc(2024));
      final back = Curriculum.fromJson(c.toJson(), createdAt: DateTime.utc(2024));
      expect(back.toJson(), c.toJson());
    });

    test('invalid colour falls back to the level palette', () {
      final level = CurriculumLevel.fromJson({'number': 2, 'color_hex': 'zzz', 'lessons': []});
      expect(level.color, isNotNull);
    });
  });
}
