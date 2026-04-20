import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/services/seed_data_service.dart';
import 'app.dart';

// Candidate .env paths tried in order:
//  1. Bundled asset (works on device + simulator)
//  2. Root project .env on the developer's Mac (simulator / macOS only)
const _kProjectEnvPath =
    '/Users/nilufar_khaydarova/Documents/Gamifiedreadingapp/.env';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress Flutter errors from showing on screen (log to console only)
  FlutterError.onError = (details) {
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('📚 Library: ${details.library}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('❌ Async Error: $error');
    return true;
  };

  // Load .env — try bundled asset first, fall back to project root file
  bool loaded = false;
  try {
    await dotenv.load(fileName: 'assets/.env');
    if (dotenv.env['ANTHROPIC_API_KEY']?.isNotEmpty == true) {
      debugPrint('✅ Loaded env from assets/.env');
      loaded = true;
    }
  } catch (_) {}

  if (!loaded) {
    try {
      final f = File(_kProjectEnvPath);
      if (await f.exists()) {
        final raw = await f.readAsString();
        // Merge into dotenv — re-parse the file content
        dotenv.testLoad(fileInput: raw);
        // Normalise: CLAUDE_API_KEY → ANTHROPIC_API_KEY
        if ((dotenv.env['ANTHROPIC_API_KEY'] ?? '').isEmpty &&
            (dotenv.env['CLAUDE_API_KEY'] ?? '').isNotEmpty) {
          dotenv.env['ANTHROPIC_API_KEY'] = dotenv.env['CLAUDE_API_KEY']!;
        }
        debugPrint('✅ Loaded env from project root .env');
        loaded = true;
      }
    } catch (e) {
      debugPrint('⚠️ Could not read project .env: $e');
    }
  }

  if (!loaded) {
    debugPrint('⚠️ No .env found — running without API keys');
    try { dotenv.testLoad(fileInput: ''); } catch (_) {}
  }

  debugPrint('✅ Booklify starting with local database...');

  // Seed demo data on first launch
  try {
    await SeedDataService.seedDatabase();
  } catch (e) {
    debugPrint('⚠️ Seed skipped: $e');
  }

  runApp(
    const ProviderScope(
      child: BooklifyApp(),
    ),
  );
}
