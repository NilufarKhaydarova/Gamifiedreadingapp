import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'data/services/seed_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');

  // Suppress errors from showing on-screen in release builds
  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    return true;
  };

  try {
    await SeedDataService.seedDatabase();
  } catch (e) {
    debugPrint('Seed error (non-fatal): $e');
  }

  runApp(
    const ProviderScope(
      child: BooklifyApp(),
    ),
  );
}
