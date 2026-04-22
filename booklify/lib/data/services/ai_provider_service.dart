import 'package:flutter/foundation.dart';
import '../../core/constants/api_keys.dart';
import 'claude_service.dart';
import 'gemini_service.dart';
import 'openai_service.dart';

// ─── AI Provider Service ──────────────────────────────────────────────────────
// Fallback chain: Claude (primary) → Gemini → OpenAI
//
// Every AI call goes through this service. It tries each provider in order
// and falls back automatically if one fails or has no API key.
// The active provider is reported back so the UI can show which one is live.

enum AiProvider { claude, gemini, openai, none }

class AiProviderService {
  final ClaudeService _claude = ClaudeService();
  final GeminiService _gemini = GeminiService();
  final OpenAIService _openai = OpenAIService();

  // ── Provider status ────────────────────────────────────────────────────────

  AiProvider get primaryAvailable {
    if (ApiKeys.hasClaudeKey) return AiProvider.claude;
    if (ApiKeys.hasGeminiKey) return AiProvider.gemini;
    if (ApiKeys.hasOpenAIKey) return AiProvider.openai;
    return AiProvider.none;
  }

  String get providerLabel => switch (primaryAvailable) {
        AiProvider.claude => 'Claude (Anthropic)',
        AiProvider.gemini => 'Gemini (Google)',
        AiProvider.openai => 'GPT-4o mini (OpenAI)',
        AiProvider.none => 'No AI configured',
      };

  // ── Socratic chat with full adaptive context ───────────────────────────────

  Future<SocraticResult> socraticChat({
    required String bookTitle,
    required String bookAuthor,
    required int currentDay,
    required int totalDays,
    required String userName,
    required List<ChatMessage> history,
    String? ragContext,          // plain text passage (legacy)
    String? adaptiveContext,     // rich XML context from AdaptiveRagService
    String? callbackContext,     // prior episode key ideas
  }) async {
    // Prefer adaptive context when available
    final fullRagContext =
        (adaptiveContext?.isNotEmpty == true) ? adaptiveContext : ragContext;

    // Try Claude
    if (ApiKeys.hasClaudeKey) {
      try {
        final reply = await _claude.socraticChat(
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
          currentPage: currentDay,
          totalPages: totalDays,
          userName: userName,
          history: history,
          ragContext: fullRagContext,
          callbackContext: callbackContext,
        );
        return SocraticResult(reply: reply, provider: AiProvider.claude);
      } catch (e) {
        debugPrint('Claude failed, trying Gemini: $e');
      }
    }

    // Fallback: Gemini
    if (ApiKeys.hasGeminiKey) {
      try {
        final reply = await _gemini.socraticChat(
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
          currentPage: currentDay,
          totalPages: totalDays,
          userName: userName,
          history: history,
          ragContext: fullRagContext,
          callbackContext: callbackContext,
        );
        return SocraticResult(reply: reply, provider: AiProvider.gemini);
      } catch (e) {
        debugPrint('Gemini failed, trying OpenAI: $e');
      }
    }

    // Last resort: OpenAI GPT-4o mini
    if (ApiKeys.hasOpenAIKey) {
      try {
        final system = _buildFallbackSystemPrompt(
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
          currentDay: currentDay,
          totalDays: totalDays,
          userName: userName,
          ragContext: fullRagContext,
          callbackContext: callbackContext,
        );
        final messages = history
            .map((m) => {'role': m.role, 'content': m.content})
            .toList();
        final reply = await _openai.chat(
          systemPrompt: system,
          messages: messages,
          maxTokens: 600,
        );
        return SocraticResult(reply: reply, provider: AiProvider.openai);
      } catch (e) {
        debugPrint('OpenAI also failed: $e');
      }
    }

    // All providers failed
    return SocraticResult(
      reply: "I'm having trouble connecting right now. "
          "What did you find most interesting in today's reading?",
      provider: AiProvider.none,
    );
  }

  String _buildFallbackSystemPrompt({
    required String bookTitle,
    required String bookAuthor,
    required int currentDay,
    required int totalDays,
    required String userName,
    String? ragContext,
    String? callbackContext,
  }) {
    final pct = totalDays > 0 ? '${(currentDay / totalDays * 100).round()}%' : 'unknown';
    return '''
You are a Socratic reading companion helping $userName read "$bookTitle" by $bookAuthor.
They are $pct through the book (day $currentDay of $totalDays).

RULES: Ask questions, never summarize. One question per response. Under 150 words.
Detect language (English/Russian/Uzbek) and respond in the same language.

${ragContext != null ? '<context>\n$ragContext\n</context>' : ''}
${callbackContext != null ? '<prior_episodes>\n$callbackContext\n</prior_episodes>' : ''}
''';
  }

  // ── Extract topic tags from an AI exchange (for analytics) ────────────────
  // Simple keyword extraction — no API call needed.

  List<String> extractTopicTags(String question) {
    const topicKeywords = {
      'character': ['character', 'protagonist', 'person', 'raskolnikov', 'hero'],
      'theme': ['theme', 'symbol', 'meaning', 'motif', 'idea'],
      'plot': ['happen', 'event', 'story', 'chapter', 'scene', 'plot'],
      'psychology': ['feel', 'mind', 'guilt', 'fear', 'emotion', 'motivation'],
      'history': ['history', 'historical', 'context', 'era', 'period', 'russia'],
      'philosophy': ['philosophy', 'moral', 'ethics', 'meaning', 'existential'],
      'language': ['word', 'language', 'translate', 'phrase', 'mean'],
      'structure': ['structure', 'style', 'author', 'narrat', 'point of view'],
    };

    final lower = question.toLowerCase();
    final tags = <String>[];
    for (final entry in topicKeywords.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) {
        tags.add(entry.key);
      }
    }
    return tags;
  }
}

// ─── Result types ─────────────────────────────────────────────────────────────

class SocraticResult {
  final String reply;
  final AiProvider provider;
  SocraticResult({required this.reply, required this.provider});

  String get providerBadge => switch (provider) {
        AiProvider.claude => '⚡ Claude',
        AiProvider.gemini => '♊ Gemini',
        AiProvider.openai => '🤖 GPT-4o',
        AiProvider.none => '⚠️ Offline',
      };
}
