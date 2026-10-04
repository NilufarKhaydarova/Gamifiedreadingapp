import 'package:booklify/data/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_env.dart';

void main() {
  test('upgrading a v1 database adds curricula + adaptive tables', () async {
    await setUpTestEnvironment();
    final path = join(await getDatabasesPath(), 'booklify.db');
    final v1 = await openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute('CREATE TABLE users (id TEXT PRIMARY KEY, '
          'email TEXT UNIQUE NOT NULL, display_name TEXT NOT NULL, '
          'password_hash TEXT NOT NULL, created_at TEXT NOT NULL, '
          'last_login_at TEXT, onboarding_complete INTEGER DEFAULT 0)');
    });
    await v1.close();

    final db = await DatabaseService().database;
    expect(await db.getVersion(), 3);
    final tables = (await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table'"))
        .map((r) => r['name'])
        .toSet();
    expect(tables, containsAll(['curricula', 'highlights', 'ai_interactions',
        'reading_analytics', 'user_reading_profile']));
  });
}
