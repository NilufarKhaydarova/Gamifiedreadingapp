import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/services/seed_data_service.dart';
import 'app.dart';

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

  // Load environment variables (non-fatal — app works without API keys)
  try {
    await dotenv.load(fileName: 'assets/.env');
    debugPrint('✅ Environment variables loaded');
  } catch (e) {
    debugPrint('⚠️ Could not load .env — running without API keys: $e');
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
