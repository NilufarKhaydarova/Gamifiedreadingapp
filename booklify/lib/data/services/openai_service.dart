import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/book.dart';
import '../../core/constants/api_keys.dart';

class OpenAIService {
  late final Dio _dio;
  final String apiKey;

  OpenAIService({String? apiKey})
      : apiKey = apiKey ?? ApiKeys.openaiApiKey,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.openai.com/v1',
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 60),
          sendTimeout: Duration(seconds: 60),
        ));

  // Chat completion for reading companion
  Future<String> chatCompletion({
    required String bookContext,
    required List<ChatMessage> messages,
    required int currentPage,
    required String userName,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiKeys.chatModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a Socratic reading companion helping someone read "$bookContext".

CONTEXT:
- User has read up to page $currentPage
- Your role: Ask questions that deepen understanding — don't summarize or give answers
- NEVER give away plot points beyond current page
- After every response, end with a question
- Keep responses under 120 words unless user asks to go deeper
- Be warm, curious, and intellectually engaged
- Address the user by name: $userName'''
            },
            ...messages.map((m) => {
              'role': m.role,
              'content': m.content,
            }).toList(),
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        },
      );

      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      // Error logged, returning fallback response
      return "I'm having trouble connecting right now. Could you try rephrasing your question?";
    }
  }

  // Generate embeddings for RAG system
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final response = await _dio.post(
        '/embeddings',
        data: {
          'model': ApiKeys.embeddingModel,
          'input': text,
        },
      );

      return List<double>.from(
        response.data['data'][0]['embedding'],
      );
    } catch (e) {
      // Embedding generation error
      throw Exception('Failed to generate embedding: $e');
    }
  }

  // Smart chunking - AI-powered episode generation
  Future<EpisodeMetadata> generateEpisodeMetadata({
    required String bookTitle,
    required String author,
    required String chunkContent,
    required int chunkNumber,
    required int totalChunks,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiKeys.chatModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a reading guide. Given a book excerpt, produce ONLY valid JSON.

Book: "$bookTitle" by $author
Excerpt: Chunk $chunkNumber of $totalChunks

Return JSON in this exact format:
{
  "episodeTitle": "short evocative title (max 5 words, like a TV episode)",
  "keyIdea": "one sentence — the core thing happening or being argued",
  "preview": "2 sentences teasing what happens, no spoilers beyond this chunk",
  "difficulty": "light|moderate|dense",
  "estimatedMinutes": <number>
}

Focus on creating engaging, Netflix-like episode titles that make readers want to continue.'''
            },
            {
              'role': 'user',
              'content': chunkContent.length > 2000
                  ? '${chunkContent.substring(0, 2000)}... [truncated]'
                  : chunkContent,
            },
          ],
          'temperature': 0.3, // Lower for consistent JSON output
          'max_tokens': 300,
        },
      );

      final responseContent = response.data['choices'][0]['message']['content'];
      final Map<String, dynamic> responseData = json.decode(responseContent);

      return EpisodeMetadata(
        episodeTitle: responseData['episodeTitle'] ?? 'Reading Episode $chunkNumber',
        keyIdea: responseData['keyIdea'] ?? 'Continue your reading journey',
        preview: responseData['preview'] ?? 'Another exciting section of the book',
        difficulty: _parseDifficulty(responseData['difficulty']),
        estimatedMinutes: responseData['estimatedMinutes'] ?? 20,
      );
    } catch (e) {
      // Episode metadata generation error
      // Fallback if AI fails
      return EpisodeMetadata(
        episodeTitle: 'Reading Episode $chunkNumber',
        keyIdea: 'Continue your reading journey',
        preview: 'Another exciting section of the book',
        difficulty: Difficulty.moderate,
        estimatedMinutes: 20,
      );
    }
  }

  // Quiz generation for comprehension testing
  Future<List<QuizQuestion>> generateQuiz({
    required String bookTitle,
    required String content,
    required int startPage,
    required int endPage,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiKeys.chatModel,
          'messages': [
            {
              'role': 'system',
              'content': '''Generate exactly 3 comprehension questions about pages $startPage-$endPage of "$bookTitle".

Format as JSON:
{
  "questions": [
    {"question": "...", "type": "open-ended", "hint": "Think about..."},
    {"question": "...", "type": "theme", "hint": null},
    {"question": "...", "type": "prediction", "hint": null}
  ]
}

Return ONLY the JSON, no other text.'''
            },
            {
              'role': 'user',
              'content': content,
            },
          ],
          'temperature': 0.5,
          'max_tokens': 500,
        },
      );

      final quizContent = response.data['choices'][0]['message']['content'];
      final Map<String, dynamic> quizData = json.decode(quizContent);
      final List<dynamic> questions = quizData['questions'];

      return questions.map((q) => QuizQuestion(
        question: q['question'],
        type: _parseQuizType(q['type']),
        hint: q['hint'],
      )).toList();
    } catch (e) {
      // Quiz generation error
      throw Exception('Failed to generate quiz: $e');
    }
  }

  // Reflection prompt response
  Future<String> generateReflectionFollowup({
    required String userReflection,
    required String bookContext,
    required int currentPage,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiKeys.chatModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a thoughtful reading companion. The user has shared a reflection about what they're reading.

Your role:
- Respond genuinely to their reflection
- Connect it to broader themes in the book
- End with a follow-up question that deepens their thinking
- Keep responses under 100 words
- Be warm and intellectually engaged'''
            },
            {
              'role': 'user',
              'content': '''
Book: "$bookContext" (page $currentPage)
User's reflection: "$userReflection"

Respond to their reflection and ask a follow-up question.'''
            },
          ],
          'temperature': 0.7,
          'max_tokens': 200,
        },
      );

      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      // Reflection followup error
      return "That's a great observation! What do you think led to that moment?";
    }
  }

  Difficulty _parseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'light':
        return Difficulty.light;
      case 'dense':
        return Difficulty.dense;
      default:
        return Difficulty.moderate;
    }
  }

  QuizType _parseQuizType(String? type) {
    switch (type?.toLowerCase()) {
      case 'open-ended':
        return QuizType.openEnded;
      case 'theme':
        return QuizType.theme;
      case 'prediction':
        return QuizType.prediction;
      default:
        return QuizType.openEnded;
    }
  }
}

// Supporting classes
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class EpisodeMetadata {
  final String episodeTitle;
  final String keyIdea;
  final String preview;
  final Difficulty difficulty;
  final int estimatedMinutes;

  EpisodeMetadata({
    required this.episodeTitle,
    required this.keyIdea,
    required this.preview,
    required this.difficulty,
    required this.estimatedMinutes,
  });
}

class QuizQuestion {
  final String question;
  final QuizType type;
  final String? hint;

  QuizQuestion({
    required this.question,
    required this.type,
    this.hint,
  });
}

enum QuizType { openEnded, theme, prediction }