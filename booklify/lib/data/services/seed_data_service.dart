import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_service.dart';

class SeedDataService {
  static final DatabaseService _db = DatabaseService();

  static Future<void> seedDatabase() async {
    await _db.initialize();

    // Check if already seeded
    final users = await _db.getLeaderboard();
    if (users.isNotEmpty) {
      debugPrint('📚 Database already seeded');
      return;
    }

    debugPrint('🌱 Starting database seeding...');

    // Create sample users
    await _createSampleUsers();

    // Create sample books
    await _createSampleBooks();

    // Create some sample progress
    await _createSampleProgress();

    debugPrint('✅ Database seeding complete!');
  }

  static Future<void> _createSampleUsers() async {
    final db = await _db.database;

    final sampleUsers = [
      {
        'id': 'user1',
        'email': 'demo@booklify.com',
        'password_hash': _hashPassword('demo123'),
        'display_name': 'Demo User',
        'xp': 2500,
        'level': 6,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'user2',
        'email': 'reader@example.com',
        'password_hash': _hashPassword('reader123'),
        'display_name': 'Avid Reader',
        'xp': 1500,
        'level': 4,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'user3',
        'email': 'learner@example.com',
        'password_hash': _hashPassword('learner123'),
        'display_name': 'Curious Learner',
        'xp': 800,
        'level': 2,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final user in sampleUsers) {
      await db.insert('users', user);
    }

    debugPrint('✅ Created ${sampleUsers.length} sample users');
  }

  static Future<void> _createSampleBooks() async {
    final db = await _db.database;

    final sampleBooks = [
      {
        'id': 'book1',
        'user_id': 'user1',
        'title': 'The Great Gatsby',
        'author': 'F. Scott Fitzgerald',
        'cover_url': 'assets/images/books/gatsby.jpg',
        'total_days': 30,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'book2',
        'user_id': 'user1',
        'title': 'To Kill a Mockingbird',
        'author': 'Harper Lee',
        'cover_url': 'assets/images/books/mockingbird.jpg',
        'total_days': 30,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'book3',
        'user_id': 'user1',
        'title': '1984',
        'author': 'George Orwell',
        'cover_url': 'assets/images/books/1984.jpg',
        'total_days': 25,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'book4',
        'user_id': 'user2',
        'title': 'Pride and Prejudice',
        'author': 'Jane Austen',
        'cover_url': 'assets/images/books/pride.jpg',
        'total_days': 35,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'book5',
        'user_id': 'user3',
        'title': 'The Catcher in the Rye',
        'author': 'J.D. Salinger',
        'cover_url': 'assets/images/books/catcher.jpg',
        'total_days': 28,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final book in sampleBooks) {
      await db.insert('books', book);
    }

    debugPrint('✅ Created ${sampleBooks.length} sample books');
  }

  static Future<void> _createSampleProgress() async {
    final db = await _db.database;

    final sampleProgress = [
      {
        'id': 'progress1',
        'user_id': 'user1',
        'book_id': 'book1',
        'current_day': 15,
        'total_days': 30,
        'completed_days': '["2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04", "2024-01-05"]',
        'xp': 750,
        'level': 2,
        'streak_days': 5,
        'start_date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'last_session_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'updated_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'progress2',
        'user_id': 'user2',
        'book_id': 'book4',
        'current_day': 20,
        'total_days': 35,
        'completed_days': '["2024-01-01", "2024-01-02", "2024-01-03"]',
        'xp': 1000,
        'level': 3,
        'streak_days': 3,
        'start_date': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        'last_session_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final progress in sampleProgress) {
      await db.insert('reading_progress', progress);
    }

    debugPrint('✅ Created ${sampleProgress.length} sample progress entries');
  }

  static String _hashPassword(String password) {
    // Use same hashing as DatabaseService (SHA-256)
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  static Future<void> clearDatabase() async {
    final db = await _db.database;

    await db.delete('reading_sessions');
    await db.delete('reading_progress');
    await db.delete('books');
    await db.delete('user_achievements');
    await db.delete('daily_challenges');
    await db.delete('users');

    debugPrint('🗑️ Database cleared');
  }

  static Future<Map<String, dynamic>> getDemoCredentials() async {
    return {
      'email': 'demo@booklify.com',
      'password': 'demo123',
      'display_name': 'Demo User',
    };
  }
}
