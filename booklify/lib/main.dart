import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/api_keys.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables - try multiple methods for iOS compatibility
  bool envLoaded = false;

  // Method 1: Load from file system (works on Android/macOS/development)
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env loaded from file system');
    envLoaded = true;
  } catch (e) {
    debugPrint('⚠️ File system load failed: $e');
  }

  // Method 2: Load from assets (works on iOS)
  if (!envLoaded) {
    try {
      final envString = await rootBundle.loadString('assets/.env');
      // Parse the env string manually and add to dotenv
      final lines = envString.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          final parts = trimmed.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();
            dotenv.env[key] = value;
          }
        }
      }
      debugPrint('✅ .env loaded from assets bundle');
      envLoaded = true;
    } catch (e) {
      debugPrint('⚠️ Assets load failed: $e');
    }
  }

  if (!envLoaded) {
    debugPrint('❌ Could not load .env file - app will run in demo mode');
  }

  // Debug: Check what keys are available
  final supabaseKey = ApiKeys.supabaseAnonKey;
  final openaiKey = ApiKeys.openaiApiKey;
  debugPrint('🔑 Supabase URL: ${ApiKeys.supabaseUrl}');
  debugPrint('🔑 Supabase key present: ${supabaseKey.isNotEmpty}');
  debugPrint('🔑 Supabase key length: ${supabaseKey.length}');
  debugPrint('🔑 OpenAI key present: ${openaiKey.isNotEmpty}');

  // Initialize Supabase only if credentials are available
  try {
    if (supabaseKey.isNotEmpty) {
      debugPrint('🔧 Attempting to initialize Supabase...');
      await Supabase.initialize(
        url: ApiKeys.supabaseUrl,
        anonKey: supabaseKey,
        debug: true,
      );
      debugPrint('✅ Supabase initialized successfully!');
    } else {
      debugPrint('⚠️ Supabase key is empty, skipping initialization');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Supabase initialization failed: $e');
    debugPrint('📚 Stack trace: $stackTrace');
  }

  runApp(
    const ProviderScope(
      child: BooklifyApp(),
    ),
  );
}
