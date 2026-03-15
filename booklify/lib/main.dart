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
    envLoaded = true;
  } catch (e) {
    // Silent fail
  }

  // Method 2: Load from assets (works on iOS)
  if (!envLoaded) {
    try {
      final envString = await rootBundle.loadString('assets/.env');
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
      envLoaded = true;
    } catch (e) {
      // Silent fail
    }
  }

  // Initialize Supabase
  final supabaseKey = ApiKeys.supabaseAnonKey;
  try {
    if (supabaseKey.isNotEmpty) {
      await Supabase.initialize(
        url: ApiKeys.supabaseUrl,
        anonKey: supabaseKey,
        debug: false,
      );
    }
  } catch (e) {
    // Continue in demo mode
  }

  runApp(
    const ProviderScope(
      child: BooklifyApp(),
    ),
  );
}
