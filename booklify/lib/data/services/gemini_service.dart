import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_keys.dart';
import 'claude_service.dart'; // for ChatMessage

// ─── Gemini Service ───────────────────────────────────────────────────────────
// Uses Gemini 2.0 Flash via REST API.
// Role: AI fallback when Claude is unavailable; multimodal tasks.
// Gemini uses "model" for assistant role (not "assistant").

class GeminiService {
  late final Dio _dio;

  GeminiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));
  }

  // ── Core message call ──────────────────────────────────────────────────────

  Future<String> _generate({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    int maxTokens = 800,
    double temperature = 0.7,
  }) async {
    if (!ApiKeys.hasGeminiKey) {
      throw Exception('Gemini API key not configured');
    }
    try {
      final response = await _dio.post(
        '/models/${ApiKeys.geminiModel}:generateContent',
        queryParameters: {'key': ApiKeys.geminiApiKey},
        data: {
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
        },
      );
      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini returned no candidates');
      }
      final parts = candidates.first['content']['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini returned empty content');
      }
      return (parts.first['text'] as String).trim();
    } on DioException catch (e) {
      debugPrint('Gemini API error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  // ── Convert ChatMessage list → Gemini contents format ─────────────────────

  List<Map<String, dynamic>> _toContents(List<ChatMessage> history) {
    return history.map((m) => {
          'role': m.role == 'assistant' ? 'model' : m.role,
          'parts': [
            {'text': m.content}
          ],
        }).toList();
  }

  // ── Socratic Chat (same contract as ClaudeService.socraticChat) ────────────

  Future<String> socraticChat({
    required String bookTitle,
    required String bookAuthor,
    required int currentPage,
    required int totalPages,
    required String userName,
    required List<ChatMessage> history,
    String? ragContext,
    String? callbackContext,
    String? readerProfile, // adaptive profile summary
  }) async {
    final progress = totalPages > 0
        ? '${(currentPage / totalPages * 100).round()}%'
        : 'unknown';

    final contextBlock = ragContext?.isNotEmpty == true
        ? '<retrieved_context>\n$ragContext\n</retrieved_context>\n'
        : '';
    final callbackBlock = callbackContext?.isNotEmpty == true
        ? '<callbacks>\n$callbackContext\n</callbacks>\n'
        : '';
    final profileBlock = readerProfile?.isNotEmpty == true
        ? '<reader_profile>\n$readerProfile\n</reader_profile>\n'
        : '';

    final system = '''
You are a Socratic reading companion helping $userName read "$bookTitle" by $bookAuthor.
They are $progress through the book (page $currentPage of $totalPages).

CRITICAL RULES:
1. ASK QUESTIONS, NEVER SUMMARISE. Every response must end with a thought-provoking question.
2. Never reveal content beyond the reader's current position.
3. Ground your responses in the actual text — reference passages when relevant.
4. One question per response.
5. Responses under 150 words unless user asks to go deeper.
6. Never produce a summary or synopsis.

Language: Detect user's language and reply in the SAME language (English/Russian/Uzbek).
Tone: Warm, intellectually curious.

$contextBlock$callbackBlock$profileBlock''';

    // Ensure alternating user/model turns (Gemini requirement)
    final contents = _toContents(history);

    return _generate(
      systemPrompt: system,
      contents: contents,
      maxTokens: 600,
    );
  }

  // ── General chat (used as fallback for any AI call) ────────────────────────

  Future<String> chat({
    required String systemPrompt,
    required List<ChatMessage> history,
    int maxTokens = 800,
  }) async {
    return _generate(
      systemPrompt: systemPrompt,
      contents: _toContents(history),
      maxTokens: maxTokens,
    );
  }
}
