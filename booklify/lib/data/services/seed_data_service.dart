import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_service.dart';

/// Seeds only the demo account.
/// Books are NOT pre-seeded — users upload their own books.
class SeedDataService {
  static final DatabaseService _db = DatabaseService();

  static Future<void> seedDatabase() async {
    // Trigger DB initialisation by accessing the database getter.
    await _db.database;

    // Only seed the demo account; skip if a demo user already exists.
    final existing = await _db.getCurrentUser();
    if (existing != null) {
      debugPrint('Database already initialised — skipping seed.');
      return;
    }

    debugPrint('Seeding demo account…');
    await _createDemoUser();
    debugPrint('Seed complete.');
  }

  static Future<void> _createDemoUser() async {
    final db = await _db.database;

    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': 'user-demo',
      'email': 'demo@booklify.com',
      'password_hash': _hashPassword('demo123'),
      'display_name': 'Demo User',
      'xp': 0,
      'level': 1,
      'created_at': now,
      'updated_at': now,
    });

    debugPrint('Demo account created: demo@booklify.com / demo123');
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
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
