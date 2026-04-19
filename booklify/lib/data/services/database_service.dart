import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart' as models;
import '../models/progress.dart';
import '../models/achievement.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final Uuid _uuid = const Uuid();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'booklify.db');

    final database = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );

    return database;
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add content and chunks_json columns to books table
      try {
        await db.execute('ALTER TABLE books ADD COLUMN content TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE books ADD COLUMN chunks_json TEXT');
      } catch (_) {}
      debugPrint('✅ DB migrated to version 2');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Books table
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        cover_url TEXT,
        total_days INTEGER DEFAULT 30,
        content TEXT,
        chunks_json TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Reading progress table
    await db.execute('''
      CREATE TABLE reading_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        current_day INTEGER DEFAULT 0,
        total_days INTEGER DEFAULT 30,
        completed_days TEXT DEFAULT '[]',
        xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        last_session_date TEXT,
        streak_days INTEGER DEFAULT 0,
        start_date TEXT,
        completed_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
        UNIQUE(user_id, book_id)
      )
    ''');

    // Reading sessions table
    await db.execute('''
      CREATE TABLE reading_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        minutes_read INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_url TEXT,
        category TEXT NOT NULL,
        target_value INTEGER NOT NULL,
        xp_reward INTEGER NOT NULL
      )
    ''');

    // User achievements table
    await db.execute('''
      CREATE TABLE user_achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE,
        UNIQUE(user_id, achievement_id)
      )
    ''');

    // Daily challenges table
    await db.execute('''
      CREATE TABLE daily_challenges (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        target_minutes INTEGER DEFAULT 15,
        completed_minutes INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        xp_reward INTEGER DEFAULT 50,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, date)
      )
    ''');

    // Insert default achievements
    await _insertDefaultAchievements(db);
  }

  Future<void> _insertDefaultAchievements(Database db) async {
    final achievements = [
      {
        'id': 'first_book',
        'title': 'Page Turner',
        'description': 'Complete your first book',
        'icon_url': 'assets/icons/achievements/book.png',
        'category': 'books',
        'target_value': 1,
        'xp_reward': 100,
      },
      {
        'id': 'streak_7',
        'title': 'Week Warrior',
        'description': 'Read for 7 days in a row',
        'icon_url': 'assets/icons/achievements/fire.png',
        'category': 'streak',
        'target_value': 7,
        'xp_reward': 150,
      },
      {
        'id': 'streak_30',
        'title': 'Monthly Master',
        'description': 'Read for 30 days in a row',
        'icon_url': 'assets/icons/achievements/calendar.png',
        'category': 'streak',
        'target_value': 30,
        'xp_reward': 500,
      },
      {
        'id': 'xp_1000',
        'title': 'Knowledge Seeker',
        'description': 'Earn 1000 total XP',
        'icon_url': 'assets/icons/achievements/star.png',
        'category': 'xp',
        'target_value': 1000,
        'xp_reward': 200,
      },
      {
        'id': 'level_5',
        'title': 'Rising Reader',
        'description': 'Reach level 5',
        'icon_url': 'assets/icons/achievements/levelup.png',
        'category': 'level',
        'target_value': 5,
        'xp_reward': 300,
      },
    ];

    for (final achievement in achievements) {
      await db.insert('achievements', achievement);
    }
  }

  Future<void> initialize() async {
    await database;
  }

  // Helper method to hash passwords
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Authentication
  Future<models.User> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final db = await database;

    final userId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final passwordHash = _hashPassword(password);

    try {
      await db.insert('users', {
        'id': userId,
        'email': email,
        'password_hash': passwordHash,
        'display_name': displayName,
        'xp': 0,
        'level': 1,
        'created_at': now,
        'updated_at': now,
      });

      return models.User(
        id: userId,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      throw Exception('Email already exists');
    }
  }

  Future<models.User> signIn({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final passwordHash = _hashPassword(password);

    debugPrint('🔐 Login attempt: $email');
    debugPrint('🔑 Input password hash: $passwordHash');

    final result = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, passwordHash],
    );

    debugPrint('🔍 Query result count: ${result.length}');

    if (result.isEmpty) {
      debugPrint('❌ Login failed: No user found');
      throw Exception('Invalid email or password');
    }

    final userData = result.first;
    return models.User(
      id: userData['id'] as String,
      email: userData['email'] as String,
      displayName: userData['display_name'] as String,
      createdAt: DateTime.parse(userData['created_at'] as String),
    );
  }

  Future<void> signOut() async {
    // Local database doesn't need sign out logic
    // Just clear current user state in the provider
  }

  Future<models.User?> getCurrentUser() async {
    // For local auth, we don't have sessions
    // Return null - the app will show login screen
    return null;
  }

  // Progress tracking
  Future<Progress> getProgress(String userId, String bookId) async {
    final db = await database;

    final result = await db.query(
      'reading_progress',
      where: 'user_id = ? AND book_id = ?',
      whereArgs: [userId, bookId],
    );

    if (result.isEmpty) {
      // Create new progress
      final newProgressId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.insert('reading_progress', {
        'id': newProgressId,
        'user_id': userId,
        'book_id': bookId,
        'current_day': 0,
        'total_days': 30,
        'completed_days': '[]',
        'xp': 0,
        'level': 1,
        'streak_days': 0,
        'start_date': now,
        'created_at': now,
        'updated_at': now,
      });

      return Progress(
        id: newProgressId,
        userId: userId,
        bookId: bookId,
        currentDay: 0,
        totalDays: 30,
        completedDays: [],
        xp: 0,
        level: 1,
        streakDays: 0,
        startDate: DateTime.now(),
      );
    }

    final data = result.first;
    return Progress(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      bookId: data['book_id'] as String,
      currentDay: data['current_day'] as int,
      totalDays: data['total_days'] as int,
      completedDays: List<String>.from(
        (data['completed_days']?.toString() != '[]' && data['completed_days'] != null)
            ? (data['completed_days'].toString()).substring(1, (data['completed_days'].toString()).length - 1).split(',')
            : [],
      ),
      xp: data['xp'] as int,
      level: data['level'] as int,
      lastSessionDate: data['last_session_date'] != null
          ? DateTime.parse(data['last_session_date'] as String)
          : null,
      streakDays: data['streak_days'] as int,
      startDate: data['start_date'] != null
          ? DateTime.parse(data['start_date'] as String)
          : null,
      completedDate: data['completed_date'] != null
          ? DateTime.parse(data['completed_date'] as String)
          : null,
    );
  }

  Future<void> syncProgress(Progress progress) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'reading_progress',
      {
        'id': progress.id.isNotEmpty ? progress.id : _uuid.v4(),
        'user_id': progress.userId,
        'book_id': progress.bookId,
        'current_day': progress.currentDay,
        'total_days': progress.totalDays,
        'completed_days': jsonEncode(progress.completedDays),
        'xp': progress.xp,
        'level': progress.level,
        'last_session_date': progress.lastSessionDate?.toIso8601String(),
        'streak_days': progress.streakDays,
        'start_date': progress.startDate?.toIso8601String(),
        'completed_date': progress.completedDate?.toIso8601String(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Achievements
  Future<List<Achievement>> fetchAchievements() async {
    final db = await database;

    final result = await db.query('achievements');

    return result.map((json) => Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String? ?? 'assets/icons/achievements/default.png',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == (json['category'] as String? ?? 'streak'),
        orElse: () => AchievementCategory.streak,
      ),
      targetValue: json['target_value'] as int,
      xpReward: json['xp_reward'] as int,
    )).toList();
  }

  Future<List<Achievement>> fetchUserAchievements(String userId) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT a.*, ua.unlocked_at
      FROM achievements a
      INNER JOIN user_achievements ua ON a.id = ua.achievement_id
      WHERE ua.user_id = ?
    ''', [userId]);

    return result.map((json) => Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String? ?? 'assets/icons/achievements/default.png',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == (json['category'] as String? ?? 'streak'),
        orElse: () => AchievementCategory.streak,
      ),
      targetValue: json['target_value'] as int,
      xpReward: json['xp_reward'] as int,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    )).toList();
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    final db = await database;

    await db.insert(
      'user_achievements',
      {
        'id': _uuid.v4(),
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Daily challenges
  Future<Map<String, dynamic>> getDailyChallenge(String userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.query(
      'daily_challenges',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );

    if (result.isEmpty) {
      // Generate new daily challenge
      final challengeId = _uuid.v4();
      final newChallenge = {
        'id': challengeId,
        'user_id': userId,
        'date': today,
        'target_minutes': 15,
        'completed_minutes': 0,
        'completed': 0,
        'xp_reward': 50,
        'created_at': DateTime.now().toIso8601String(),
      };

      await db.insert('daily_challenges', newChallenge);
      return newChallenge;
    }

    return result.first;
  }

  Future<void> updateDailyChallenge(
    String userId,
    int additionalMinutes,
  ) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final current = await getDailyChallenge(userId);
    final completedMinutes = (current['completed_minutes'] as int) + additionalMinutes;
    final targetMinutes = current['target_minutes'] as int;

    await db.update(
      'daily_challenges',
      {
        'completed_minutes': completedMinutes,
        'completed': completedMinutes >= targetMinutes ? 1 : 0,
      },
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );
  }

  // Leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final db = await database;

    final result = await db.query(
      'users',
      columns: ['id', 'display_name', 'xp', 'level'],
      orderBy: 'xp DESC',
      limit: 100,
    );

    return result.map((row) => {
      'id': row['id'],
      'display_name': row['display_name'],
      'xp': row['xp'],
      'level': row['level'],
    }).toList();
  }

  // Check streak
  Future<int> getUserStreak(String userId) async {
    final db = await database;

    final result = await db.query(
      'reading_sessions',
      columns: ['created_at'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 30,
    );

    if (result.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;
    DateTime? checkDate;

    for (final session in result) {
      final sessionDate = DateTime.parse(session['created_at'] as String);

      if (checkDate == null) {
        final daysDiff = now.difference(sessionDate).inDays;
        if (daysDiff <= 1) {
          streak++;
          checkDate = sessionDate;
        } else {
          break;
        }
      } else {
        final daysDiff = checkDate.difference(sessionDate).inDays;
        if (daysDiff <= 1) {
          streak++;
          checkDate = sessionDate;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  // Log reading session
  Future<void> logReadingSession({
    required String userId,
    required String bookId,
    required int minutesRead,
    required int dayNumber,
  }) async {
    final db = await database;

    await db.insert('reading_sessions', {
      'id': _uuid.v4(),
      'user_id': userId,
      'book_id': bookId,
      'minutes_read': minutesRead,
      'day_number': dayNumber,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Update user XP and level
  Future<void> updateUserXP(String userId, int xpToAdd) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      final currentXP = result.first['xp'] as int;
      final newXP = currentXP + xpToAdd;
      final newLevel = (newXP ~/ 500) + 1; // Level up every 500 XP

      await db.update(
        'users',
        {
          'xp': newXP,
          'level': newLevel,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    }
  }

  // Get user XP and level
  Future<Map<String, int>> getUserXP(String userId) async {
    final db = await database;

    final result = await db.query(
      'users',
      columns: ['xp', 'level'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isEmpty) {
      return {'xp': 0, 'level': 1};
    }

    return {
      'xp': result.first['xp'] as int,
      'level': result.first['level'] as int,
    };
  }

  // ─── Book Management ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBooks(String userId) async {
    final db = await database;
    return db.query(
      'books',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getBook(String bookId) async {
    final db = await database;
    final result = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  Future<void> saveBook({
    required String id,
    required String userId,
    required String title,
    required String author,
    String? coverUrl,
    int totalDays = 7,
    String? content,
    String? chunksJson,
  }) async {
    final db = await database;
    await db.insert(
      'books',
      {
        'id': id,
        'user_id': userId,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'total_days': totalDays,
        'content': content,
        'chunks_json': chunksJson,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBookChunks(String bookId, String chunksJson) async {
    final db = await database;
    await db.update(
      'books',
      {'chunks_json': chunksJson},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> deleteBook(String bookId) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  Future<Map<String, dynamic>?> getReadingProgressForBook(
      String userId, String bookId) async {
    final db = await database;
    final result = await db.query(
      'reading_progress',
      where: 'user_id = ? AND book_id = ?',
      whereArgs: [userId, bookId],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }
}
