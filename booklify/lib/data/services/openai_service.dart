import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_keys.dart';

// ─── OpenAI Service ───────────────────────────────────────────────────────────
// Kept ONLY for embeddings (text-embedding-3-small).
// All chat / reasoning calls have moved to ClaudeService.

class OpenAIService {
  late final Dio _dio;

  OpenAIService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.openai.com/v1',
      headers: {
        'Authorization': 'Bearer ${ApiKeys.openaiApiKey}',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  /// Generate a dense embedding vector for [text].
  /// Uses text-embedding-3-small (1536 dims).
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final response = await _dio.post(
        '/embeddings',
        data: {
          'model': ApiKeys.embeddingModel,
          'input': text,
        },
      );
      return List<double>.from(response.data['data'][0]['embedding']);
    } on DioException catch (e) {
      debugPrint('❌ OpenAI embedding error: ${e.response?.data ?? e.message}');
      throw Exception('Failed to generate embedding: $e');
    }
  }

  /// Chat completion — used as last-resort fallback after Claude and Gemini.
  Future<String> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 600,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages,
          ],
          'max_tokens': maxTokens,
          'temperature': 0.7,
        },
      );
      return response.data['choices'][0]['message']['content'] as String;
    } on DioException catch (e) {
      debugPrint('❌ OpenAI chat error: ${e.response?.data ?? e.message}');
      throw Exception('OpenAI chat failed: $e');
    }
  }

  /// Batch-embed multiple texts in one API call.
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    try {
      final response = await _dio.post(
        '/embeddings',
        data: {
          'model': ApiKeys.embeddingModel,
          'input': texts,
        },
      );
      final data = response.data['data'] as List;
      // Sort by index to preserve order
      data.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
      return data.map((d) => List<double>.from(d['embedding'])).toList();
    } on DioException catch (e) {
      debugPrint('❌ OpenAI batch embedding error: ${e.response?.data ?? e.message}');
      throw Exception('Failed to generate embeddings: $e');
    }
  }
}
