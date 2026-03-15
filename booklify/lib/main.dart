import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/api_keys.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to load environment variables, but don't fail if missing
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file not found - will use default values
  }

  // Initialize Supabase only if credentials are available
  try {
    if (ApiKeys.supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: ApiKeys.supabaseUrl,
        anonKey: ApiKeys.supabaseAnonKey,
      );
    }
  } catch (e) {
    // Continue in demo mode if Supabase fails to initialize
  }

  runApp(
    const ProviderScope(
      child: BooklifyApp(),
    ),
  );
}