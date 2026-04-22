import 'package:flutter/foundation.dart';
import 'database_service.dart';

/// Seeds only the demo account.
/// Books are NOT pre-seeded — users upload their own books.
class SeedDataService {
  static final DatabaseService _db = DatabaseService();

  static Future<void> seedDatabase() async {
    await _db.database;
    debugPrint('Seeding demo account…');
    await _upsertDemoUser();
    debugPrint('Seed complete.');
  }

  static Future<void> _upsertDemoUser() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final correctHash = _db.hashPassword('demo123');

    final existing = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: ['user-demo'],
    );

    if (existing.isEmpty) {
      await db.insert('users', {
        'id': 'user-demo',
        'email': 'demo@booklify.com',
        'password_hash': correctHash,
        'display_name': 'Demo User',
        'created_at': now,
      });
      debugPrint('Demo account created: demo@booklify.com / demo123');
    } else if (existing.first['password_hash'] != correctHash) {
      await db.update(
        'users',
        {'password_hash': correctHash},
        where: 'id = ?',
        whereArgs: ['user-demo'],
      );
      debugPrint('Demo account hash corrected.');
    }
  }

  static Future<Map<String, dynamic>> getDemoCredentials() async {
    return {
      'email': 'demo@booklify.com',
      'password': 'demo123',
      'display_name': 'Demo User',
    };
  }

  /// Completely wipes all tables. Use for testing only.
  static Future<void> clearDatabase() async {
    final db = await _db.database;
    await db.delete('reading_sessions');
    await db.delete('reading_progress');
    await db.delete('books');
    await db.delete('user_achievements');
    await db.delete('daily_challenges');
    await db.delete('users');
    debugPrint('Database cleared.');
  }
}
