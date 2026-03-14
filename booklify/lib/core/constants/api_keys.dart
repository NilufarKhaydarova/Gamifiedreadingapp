import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  // OpenAI Configuration
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // OpenAI Models
  static const String chatModel = 'gpt-4';
  static const String embeddingModel = 'text-embedding-3-small';

  // Supabase Configuration
  static const String supabaseUrl = 'https://jbjmdglmxfrdbmnnduuo.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Langfuse Configuration (for AI observability)
  static String get langfusePublicKey => dotenv.env['LANGFUSE_PUBLIC_KEY'] ?? '';
  static String get langfuseSecretKey => dotenv.env['LANGFUSE_SECRET_KEY'] ?? '';
  static const String langfuseBaseUrl = 'http://localhost:3000';
}