import 'dart:io';

import 'package:booklify/data/models/book.dart';
import 'package:booklify/data/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

// Runs the real DatabaseService against SQLite via FFI. The service caches its
// connection statically, so each test uses unique emails / ids.

String _email() => '${const Uuid().v4()}@test.dev';

Book _book({String? id, String content = 'Some text'}) => Book(
      id: id ?? const Uuid().v4(),
      title: 'Dune',
      author: 'Frank Herbert',
      totalPages: 600,
      content: content,
      uploadDate: DateTime.utc(2024, 1, 1),
      chunks: [
        BookChunk(
          id: 'day-1',
          dayNumber: 1,
          episodeTitle: 'Chapter 1',
          keyIdea: '',
          preview: 'Some',
          difficulty: Difficulty.light,
          estimatedMinutes: 5,
          startOffset: 0,
          endOffset: 9,
        ),
      ],
    );

void main() {
  late DatabaseService db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('booklify_db_test');
    await databaseFactory.setDatabasesPath(dir.path);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = DatabaseService();
  });

  group('auth', () {
    test('sign up, sign out, sign in, current user', () async {
      final email = _email();
      final user = await db.signUp(email: email, password: 'pw123456', displayName: 'Ann');
      expect(user.email, email);
      expect((await db.getCurrentUser())?.id, user.id);

      await db.signOut();
      expect(await db.getCurrentUser(), isNull);

      final again = await db.signIn(email: email.toUpperCase(), password: 'pw123456');
      expect(again.id, user.id);
      expect((await db.getCurrentUser())?.displayName, 'Ann');
    });

    test('duplicate email is rejected', () async {
      final email = _email();
      await db.signUp(email: email, password: 'pw', displayName: 'A');
      expect(
        () => db.signUp(email: email, password: 'pw', displayName: 'B'),
        throwsA(isA<Exception>()),
      );
    });

    test('wrong password is rejected', () async {
      final email = _email();
      await db.signUp(email: email, password: 'right', displayName: 'A');
      expect(() => db.signIn(email: email, password: 'wrong'), throwsA(isA<Exception>()));
    });

    test('passwords are not stored in plain text', () {
      expect(db.hashPassword('secret'), isNot('secret'));
      expect(db.hashPassword('secret'), db.hashPassword('secret'));
      expect(db.hashPassword('secret'), isNot(db.hashPassword('secret2')));
    });
  });

  group('books', () {
    test('save, list, update chunks, delete', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      final book = _book();
      await db.saveBook(book, user.id);

      final books = await db.getBooks(user.id);
      expect(books.map((b) => b.id), [book.id]);
      expect(books.single.chunks.single.episodeTitle, 'Chapter 1');

      final done = book.chunks.single.copyWith(completed: true, completedDate: DateTime.now());
      await db.updateBookChunks(book.id, [done]);
      expect((await db.getBook(book.id))!.chunks.single.completed, isTrue);

      await db.deleteBook(book.id);
      expect(await db.getBook(book.id), isNull);
      expect(await db.getBooks(user.id), isEmpty);
    });

    test("users only see their own books", () async {
      final a = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      final b = await db.signUp(email: _email(), password: 'pw', displayName: 'B');
      await db.saveBook(_book(), a.id);
      expect(await db.getBooks(b.id), isEmpty);
    });
  });

  group('progress', () {
    test('getOrCreateProgress creates once, then returns the saved progress', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      final p = await db.getOrCreateProgress(user.id, 'book-x', totalDays: 12);
      expect(p.totalDays, 12);

      final updated = p.copyWith(currentDay: 1).completeDay();
      await db.saveProgress(updated);

      final loaded = await db.getOrCreateProgress(user.id, 'book-x');
      expect(loaded.id, p.id);
      expect(loaded.xp, 50);
      expect(loaded.currentDay, 2);
      expect(loaded.completedDays, hasLength(1));
    });
  });

  group('achievements', () {
    test('8 achievements are seeded', () async {
      expect(await db.getAchievements(), hasLength(8));
    });

    test('progress unlocks matching achievements only once', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      final p = (await db.getOrCreateProgress(user.id, 'b', totalDays: 30))
          .copyWith(currentDay: 1)
          .completeDay();

      final first = await db.checkAndUnlockAchievements(user.id, p);
      expect(first.map((a) => a.id), contains('first_steps'));

      final second = await db.checkAndUnlockAchievements(user.id, p);
      expect(second, isEmpty);
      expect((await db.getUserAchievements(user.id)).map((a) => a.id), contains('first_steps'));
    });
  });

  group('daily challenge & sessions', () {
    test('daily challenge is created at 15 min and completes after enough reading', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      final c = await db.getDailyChallenge(user.id);
      expect(c['target_minutes'], 15);
      expect(c['completed'], isFalse);

      await db.updateDailyChallenge(user.id, 10);
      expect((await db.getDailyChallenge(user.id))['completed'], isFalse);
      await db.updateDailyChallenge(user.id, 6);
      final done = await db.getDailyChallenge(user.id);
      expect(done['completed_minutes'], 16);
      expect(done['completed'], isTrue);
    });

    test('reading sessions add up and count toward the streak', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      expect(await db.getUserStreak(user.id), 0);
      await db.logReadingSession(userId: user.id, bookId: 'b', minutesRead: 20, dayNumber: 1);
      await db.logReadingSession(userId: user.id, bookId: 'b', minutesRead: 15, dayNumber: 1);
      expect(await db.getTotalReadingMinutes(user.id), 35);
      expect(await db.getUserStreak(user.id), 1);
    });

    Future<void> logAt(String userId, DateTime when) async {
      final raw = await db.database;
      await raw.insert('reading_sessions', {
        'id': const Uuid().v4(),
        'user_id': userId,
        'book_id': 'b',
        'minutes_read': 10,
        'day_number': 1,
        'created_at': when.toIso8601String(),
      });
    }

    DateTime daysAgo(int n, [int hour = 10]) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - n, hour);
    }

    test('a missed day breaks the streak', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      await logAt(user.id, DateTime.now());
      await logAt(user.id, daysAgo(2));
      expect(await db.getUserStreak(user.id), 1);
    });

    test('consecutive days count, several sessions a day count once', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      for (final d in [daysAgo(0, 8), daysAgo(0, 20), daysAgo(1, 23), daysAgo(2, 1), daysAgo(4)]) {
        await logAt(user.id, d);
      }
      expect(await db.getUserStreak(user.id), 3);
    });

    test('the streak survives until the reader reads today', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      await logAt(user.id, daysAgo(1));
      await logAt(user.id, daysAgo(2));
      expect(await db.getUserStreak(user.id), 2);
    });

    test('nothing since the day before yesterday means no streak', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      await logAt(user.id, daysAgo(2));
      expect(await db.getUserStreak(user.id), 0);
    });
  });

  group('curriculum & adaptive RAG storage', () {
    test('save, read, update progress and delete a curriculum', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      expect(await db.hasCurriculum(user.id), isFalse);
      await db.saveCurriculum({'title': 'Stoicism', 'levels': []}, userId: user.id, topic: 'stoicism');
      expect(await db.hasCurriculum(user.id), isTrue);
      expect((await db.getCurriculum(user.id))!['title'], 'Stoicism');
      await db.deleteCurriculum(user.id);
      expect(await db.hasCurriculum(user.id), isFalse);
    });

    test('highlights and AI interactions are stored per book', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      await db.saveHighlight(
          userId: user.id, bookId: 'b1', chunkId: 'day-1', text: 'Fear is the mind-killer', positionPct: 0.3);
      await db.saveAiInteraction(
        userId: user.id, bookId: 'b1', chunkId: 'day-1', question: 'Why?', response: 'Because');

      expect((await db.getHighlights(user.id, 'b1')).single['text'], 'Fear is the mind-killer');
      expect(await db.getHighlights(user.id, 'other'), isEmpty);
      expect(await db.getAiInteractions(user.id, 'b1'), hasLength(1));
    });

    test('reader profile has defaults and can be updated', () async {
      final user = await db.signUp(email: _email(), password: 'pw', displayName: 'A');
      final profile = await db.getUserReadingProfile(user.id);
      expect(profile, isNotEmpty);
      expect(profile['preferredDepth'], 'unknown');
      await db.updateUserReadingProfile(user.id, {...profile, 'highlightThemes': ['spice']});
      expect((await db.getUserReadingProfile(user.id))['highlightThemes'], ['spice']);
    });
  });
}
