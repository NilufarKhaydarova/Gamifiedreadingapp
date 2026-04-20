import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  // ── Claude (primary AI for all reasoning + chat) ──────────────────────────
  static String get anthropicApiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static const String claudeModel = 'claude-sonnet-4-5';
  static const String claudeHaikuModel = 'claude-haiku-4-5'; // fast, cheap
  static bool get hasClaudeKey =>
      anthropicApiKey.isNotEmpty && anthropicApiKey != 'your_anthropic_api_key_here';

  // ── OpenAI (embeddings only) ──────────────────────────────────────────────
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String embeddingModel = 'text-embedding-3-small';
  static bool get hasOpenAIKey => openaiApiKey.isNotEmpty;

  // ── Gemini (multimodal / book cover analysis) ─────────────────────────────
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String geminiModel = 'gemini-2.0-flash';
  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'your_gemini_api_key_here';

  // ── Observability ─────────────────────────────────────────────────────────
  static String get langfusePublicKey => dotenv.env['LANGFUSE_PUBLIC_KEY'] ?? '';
  static String get langfuseSecretKey => dotenv.env['LANGFUSE_SECRET_KEY'] ?? '';
  static String get langfuseBaseUrl =>
      dotenv.env['LANGFUSE_BASE_URL'] ?? 'http://localhost:3000';

  // ── Fallback chain ────────────────────────────────────────────────────────
  /// Which AI provider is available for chat/reasoning?
  static AiProvider get chatProvider {
    if (hasClaudeKey) return AiProvider.claude;
    if (hasGeminiKey) return AiProvider.gemini;
    return AiProvider.none;
  }
}

enum AiProvider { claude, gemini, none }
