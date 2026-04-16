import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart' as models;
import '../models/book.dart';
import '../models/progress.dart';
import '../models/achievement.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'booklify.db';
  static const int _dbVersion = 1;
  static const String _currentUserKey = 'current_user_id';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login_at TEXT,
        onboarding_complete INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT DEFAULT 'Unknown',
        total_pages INTEGER DEFAULT 0,
        content TEXT DEFAULT '',
        upload_date TEXT NOT NULL,
        language TEXT DEFAULT 'en',
        description TEXT,
        chunks_json TEXT DEFAULT '[]',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        current_day INTEGER DEFAULT 0,
        total_days INTEGER DEFAULT 30,
        completed_days_json TEXT DEFAULT '[]',
        xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        streak_days INTEGER DEFAULT 0,
        start_date TEXT,
        last_session_date TEXT,
        completed_date TEXT,
        updated_at TEXT,
        UNIQUE(user_id, book_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        minutes_read INTEGER DEFAULT 0,
        day_number INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        icon_url TEXT,
        category TEXT DEFAULT 'streak',
        target_value INTEGER DEFAULT 1,
        xp_reward INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        UNIQUE(user_id, achievement_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (achievement_id) REFERENCES achievements(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_challenges (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        target_minutes INTEGER DEFAULT 15,
        completed_minutes INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        xp_reward INTEGER DEFAULT 50,
        UNIQUE(user_id, date),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await _seedAchievements(db);
  }

  Future<void> _seedAchievements(Database db) async {
    final achievements = [
      {
        'id': 'first_steps',
        'title': 'First Steps',
        'description': 'Complete your first reading day',
        'category': 'streak',
        'target_value': 1,
        'xp_reward': 50,
      },
      {
        'id': 'week_warrior',
        'title': 'Week Warrior',
        'description': 'Maintain a 7-day reading streak',
        'category': 'streak',
        'target_value': 7,
        'xp_reward': 150,
      },
      {
        'id': 'dedicated_reader',
        'title': 'Dedicated Reader',
        'description': '14 consecutive reading days',
        'category': 'streak',
        'target_value': 14,
        'xp_reward': 300,
      },
      {
        'id': 'monthly_master',
        'title': 'Monthly Master',
        'description': '30-day reading streak',
        'category': 'streak',
        'target_value': 30,
        'xp_reward': 1000,
      },
      {
        'id': 'bookworm',
        'title': 'Bookworm',
        'description': 'Finish reading a complete book',
        'category': 'readingSpeed',
        'target_value': 1,
        'xp_reward': 500,
      },
      {
        'id': 'speed_reader',
        'title': 'Speed Reader',
        'description': 'Complete 5 reading sessions',
        'category': 'readingSpeed',
        'target_value': 5,
        'xp_reward': 200,
      },
      {
        'id': 'perfect_score',
        'title': 'Perfect Score',
        'description': 'Read for 7 days in a single week',
        'category': 'comprehension',
        'target_value': 7,
        'xp_reward': 100,
      },
      {
        'id': 'social_butterfly',
        'title': 'Social Butterfly',
        'description': 'Have 10 AI chat conversations',
        'category': 'social',
        'target_value': 10,
        'xp_reward': 200,
      },
    ];

    for (final a in achievements) {
      await db.insert('achievements', {
        'id': a['id'],
        'title': a['title'],
        'description': a['description'],
        'icon_url': 'assets/icons/achievements/${a['id']}.png',
        'category': a['category'],
        'target_value': a['target_value'],
        'xp_reward': a['xp_reward'],
      });
    }
  }

  // Simple password hashing for local app
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'booklify_salt_2024');
    int hash = 5381;
    for (final b in bytes) {
      hash = ((hash << 5) + hash) + b;
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // ─── AUTH ────────────────────────────────────────────────────────────────

  Future<models.User> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final db = await database;
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final existing = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (existing.isNotEmpty) {
      throw Exception('An account with that email already exists.');
    }

    await db.insert('users', {
      'id': id,
      'email': email.toLowerCase(),
      'display_name': displayName,
      'password_hash': _hashPassword(password),
      'created_at': now,
      'onboarding_complete': 0,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, id);

    return models.User(
      id: id,
      email: email.toLowerCase(),
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  Future<models.User> signIn({
    required String email,
    required String password,
  }) async {
    final db = await database;

    final results = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.toLowerCase(), _hashPassword(password)],
    );

    if (results.isEmpty) {
      throw Exception('Invalid email or password.');
    }

    final userData = results.first;
    final id = userData['id'] as String;

    await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, id);

    return models.User(
      id: id,
      email: userData['email'] as String,
      displayName: userData['display_name'] as String,
      createdAt: DateTime.parse(userData['created_at'] as String),
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<models.User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserKey);
    if (userId == null) return null;

    final db = await database;
    final results =
        await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (results.isEmpty) return null;

    final userData = results.first;
    return models.User(
      id: userData['id'] as String,
      email: userData['email'] as String,
      displayName: userData['display_name'] as String,
      createdAt: DateTime.parse(userData['created_at'] as String),
    );
  }

  // ─── BOOKS ───────────────────────────────────────────────────────────────

  Future<List<Book>> getBooks(String userId) async {
    final db = await database;
    final results = await db.query(
      'books',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'upload_date DESC',
    );
    return results.map(_bookFromRow).toList();
  }

  Future<Book?> getBook(String bookId) async {
    final db = await database;
    final results =
        await db.query('books', where: 'id = ?', whereArgs: [bookId]);
    if (results.isEmpty) return null;
    return _bookFromRow(results.first);
  }

  Book _bookFromRow(Map<String, dynamic> row) {
    List<BookChunk> chunks = [];
    final chunksJson = row['chunks_json'] as String?;
    if (chunksJson != null && chunksJson != '[]') {
      try {
        final data = json.decode(chunksJson) as List;
        chunks = data
            .map((c) => BookChunk.fromJson(c as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error parsing chunks: $e');
      }
    }

    return Book(
      id: row['id'] as String,
      title: row['title'] as String,
      author: row['author'] as String? ?? 'Unknown',
      totalPages: row['total_pages'] as int? ?? 0,
      content: row['content'] as String? ?? '',
      uploadDate: DateTime.parse(row['upload_date'] as String),
      language: row['language'] as String? ?? 'en',
      description: row['description'] as String?,
      chunks: chunks,
    );
  }

  Future<String> saveBook(Book book, String userId) async {
    final db = await database;
    final id = book.id.isNotEmpty ? book.id : const Uuid().v4();

    await db.insert(
      'books',
      {
        'id': id,
        'user_id': userId,
        'title': book.title,
        'author': book.author,
        'total_pages': book.totalPages,
        'content': book.content,
        'upload_date': book.uploadDate.toIso8601String(),
        'language': book.language ?? 'en',
        'description': book.description,
        'chunks_json':
            json.encode(book.chunks.map((c) => c.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<void> updateBookChunks(String bookId, List<BookChunk> chunks) async {
    final db = await database;
    await db.update(
      'books',
      {'chunks_json': json.encode(chunks.map((c) => c.toJson()).toList())},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> deleteBook(String bookId) async {
    final db = await database;
    await db.delete('reading_progress',
        where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('reading_sessions',
        where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  // ─── PROGRESS ────────────────────────────────────────────────────────────

  Future<Progress> getOrCreateProgress(String userId, String bookId,
      {int totalDays = 30}) async {
    final db = await database;
    final results = await db.query(
      'reading_progress',
      where: 'user_id = ? AND book_id = ?',
      whereArgs: [userId, bookId],
    );

    if (results.isEmpty) {
      final id = const Uuid().v4();
      final progress = Progress(
        id: id,
        userId: userId,
        bookId: bookId,
        currentDay: 0,
        totalDays: totalDays,
        completedDays: [],
        xp: 0,
        level: 1,
        streakDays: 0,
        startDate: DateTime.now(),
      );
      await saveProgress(progress);
      return progress;
    }

    return _progressFromRow(results.first);
  }

  Progress _progressFromRow(Map<String, dynamic> row) {
    List<String> completedDays = [];
    try {
      completedDays = List<String>.from(
          json.decode(row['completed_days_json'] as String? ?? '[]'));
    } catch (_) {}

    return Progress(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      bookId: row['book_id'] as String,
      currentDay: row['current_day'] as int? ?? 0,
      totalDays: row['total_days'] as int? ?? 30,
      completedDays: completedDays,
      xp: row['xp'] as int? ?? 0,
      level: row['level'] as int? ?? 1,
      streakDays: row['streak_days'] as int? ?? 0,
      startDate: row['start_date'] != null
          ? DateTime.parse(row['start_date'] as String)
          : null,
      lastSessionDate: row['last_session_date'] != null
          ? DateTime.parse(row['last_session_date'] as String)
          : null,
      completedDate: row['completed_date'] != null
          ? DateTime.parse(row['completed_date'] as String)
          : null,
    );
  }

  Future<void> saveProgress(Progress progress) async {
    final db = await database;
    await db.insert(
      'reading_progress',
      {
        'id': progress.id,
        'user_id': progress.userId,
        'book_id': progress.bookId,
        'current_day': progress.currentDay,
        'total_days': progress.totalDays,
        'completed_days_json': json.encode(progress.completedDays),
        'xp': progress.xp,
        'level': progress.level,
        'streak_days': progress.streakDays,
        'start_date': progress.startDate?.toIso8601String(),
        'last_session_date': progress.lastSessionDate?.toIso8601String(),
        'completed_date': progress.completedDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── ACHIEVEMENTS ─────────────────────────────────────────────────────────

  Future<List<Achievement>> getAchievements() async {
    final db = await database;
    final results =
        await db.query('achievements', orderBy: 'xp_reward ASC');
    return results.map(_achievementFromRow).toList();
  }

  Future<List<Achievement>> getUserAchievements(String userId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT a.*, ua.unlocked_at
      FROM achievements a
      INNER JOIN user_achievements ua ON a.id = ua.achievement_id
      WHERE ua.user_id = ?
      ORDER BY ua.unlocked_at DESC
    ''', [userId]);

    return results
        .map((row) => _achievementFromRow(row,
            unlockedAt: DateTime.parse(row['unlocked_at'] as String)))
        .toList();
  }

  Achievement _achievementFromRow(Map<String, dynamic> row,
      {DateTime? unlockedAt}) {
    return Achievement(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      iconUrl: row['icon_url'] as String? ??
          'assets/icons/achievements/default.png',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == (row['category'] as String? ?? 'streak'),
        orElse: () => AchievementCategory.streak,
      ),
      targetValue: row['target_value'] as int? ?? 1,
      xpReward: row['xp_reward'] as int? ?? 0,
      unlockedAt: unlockedAt,
    );
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    final db = await database;
    try {
      await db.insert(
        'user_achievements',
        {
          'id': const Uuid().v4(),
          'user_id': userId,
          'achievement_id': achievementId,
          'unlocked_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      debugPrint('Achievement unlock error (may already be unlocked): $e');
    }
  }

  /// Check and unlock achievements based on current progress.
  Future<List<Achievement>> checkAndUnlockAchievements(
      String userId, Progress progress) async {
    final db = await database;
    final allAchievements = await getAchievements();
    final userAchievements = await getUserAchievements(userId);
    final unlockedIds = userAchievements.map((a) => a.id).toSet();

    final sessionCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM reading_sessions WHERE user_id = ?',
            [userId])) ??
        0;

    final newlyUnlocked = <Achievement>[];

    for (final achievement in allAchievements) {
      if (unlockedIds.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'first_steps':
          shouldUnlock = progress.completedDays.isNotEmpty;
          break;
        case 'week_warrior':
          shouldUnlock = progress.streakDays >= 7;
          break;
        case 'dedicated_reader':
          shouldUnlock = progress.streakDays >= 14;
          break;
        case 'monthly_master':
          shouldUnlock = progress.streakDays >= 30;
          break;
        case 'bookworm':
          shouldUnlock = progress.isCompleted;
          break;
        case 'speed_reader':
          shouldUnlock = sessionCount >= 5;
          break;
        case 'perfect_score':
          shouldUnlock = progress.completedDays.length >= 7;
          break;
        case 'social_butterfly':
          // Checked separately via chat count
          break;
      }

      if (shouldUnlock) {
        await unlockAchievement(userId, achievement.id);
        newlyUnlocked
            .add(achievement.copyWith(unlockedAt: DateTime.now()));
      }
    }

    return newlyUnlocked;
  }

  // ─── DAILY CHALLENGES ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailyChallenge(String userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final results = await db.query(
      'daily_challenges',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );

    if (results.isEmpty) {
      final id = const Uuid().v4();
      await db.insert('daily_challenges', {
        'id': id,
        'user_id': userId,
        'date': today,
        'target_minutes': 15,
        'completed_minutes': 0,
        'completed': 0,
        'xp_reward': 50,
      });
      return {
        'target_minutes': 15,
        'completed_minutes': 0,
        'completed': false,
        'xp_reward': 50,
      };
    }

    final row = results.first;
    return {
      'target_minutes': row['target_minutes'] as int,
      'completed_minutes': row['completed_minutes'] as int,
      'completed': (row['completed'] as int) == 1,
      'xp_reward': row['xp_reward'] as int,
    };
  }

  Future<void> updateDailyChallenge(
      String userId, int additionalMinutes) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final current = await getDailyChallenge(userId);
    final newMinutes =
        (current['completed_minutes'] as int) + additionalMinutes;
    final isCompleted =
        newMinutes >= (current['target_minutes'] as int);

    await db.update(
      'daily_challenges',
      {
        'completed_minutes': newMinutes,
        'completed': isCompleted ? 1 : 0,
      },
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );
  }

  // ─── READING SESSIONS ─────────────────────────────────────────────────────

  Future<void> logReadingSession({
    required String userId,
    required String bookId,
    required int minutesRead,
    required int dayNumber,
  }) async {
    final db = await database;
    await db.insert('reading_sessions', {
      'id': const Uuid().v4(),
      'user_id': userId,
      'book_id': bookId,
      'minutes_read': minutesRead,
      'day_number': dayNumber,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getUserStreak(String userId) async {
    final db = await database;
    final results = await db.query(
      'reading_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 60,
      columns: ['created_at'],
    );

    if (results.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;
    String? lastDateStr;

    for (final session in results) {
      final sessionDate =
          DateTime.parse(session['created_at'] as String);
      final dateStr =
          sessionDate.toIso8601String().split('T')[0];

      if (lastDateStr == null) {
        final daysDiff = now.difference(sessionDate).inDays;
        if (daysDiff <= 1) {
          streak++;
          lastDateStr = dateStr;
        } else {
          break;
        }
      } else {
        final lastDate = DateTime.parse(lastDateStr);
        final daysDiff = lastDate.difference(sessionDate).inDays;
        if (daysDiff <= 1 && dateStr != lastDateStr) {
          streak++;
          lastDateStr = dateStr;
        } else if (dateStr == lastDateStr) {
          continue; // Same day, skip
        } else {
          break;
        }
      }
    }

    return streak;
  }

  Future<int> getTotalReadingMinutes(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(minutes_read) as total FROM reading_sessions WHERE user_id = ?',
        [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalBooksRead(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM reading_progress WHERE user_id = ? AND completed_date IS NOT NULL',
        [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
