import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../../core/constants/api_keys.dart';

// ─── Claude Service ───────────────────────────────────────────────────────────
// Primary AI for all reasoning, Socratic chat, curriculum, and quizzes.
// Model: claude-sonnet-4-5 (reasoning-heavy tasks)
//        claude-haiku-4-5  (fast metadata, quiz generation)

class ClaudeService {
  late final Dio _dio;

  ClaudeService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.anthropic.com/v1',
      headers: {
        'x-api-key': ApiKeys.anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 30),
    ));
  }

  // ── Core message call ──────────────────────────────────────────────────────

  Future<String> _message({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    String model = ApiKeys.claudeModel,
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    try {
      final response = await _dio.post(
        '/messages',
        data: {
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'system': systemPrompt,
          'messages': messages,
        },
      );
      final content = response.data['content'] as List;
      return (content.first['text'] as String).trim();
    } on DioException catch (e) {
      debugPrint('❌ Claude API error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  // ── Socratic Reading Companion ─────────────────────────────────────────────

  Future<String> socraticChat({
    required String bookTitle,
    required String bookAuthor,
    required int currentPage,
    required int totalPages,
    required String userName,
    required List<ChatMessage> history,
    String? ragContext,        // injected book passages
    String? callbackContext,   // cross-episode narrative callbacks
  }) async {
    final progress = totalPages > 0
        ? '${(currentPage / totalPages * 100).round()}%'
        : 'unknown';

    final contextBlock = ragContext != null && ragContext.isNotEmpty
        ? '''
<retrieved_context>
$ragContext
</retrieved_context>
''' : '';

    final callbackBlock = callbackContext != null && callbackContext.isNotEmpty
        ? '''
<callbacks>
$callbackContext
</callbacks>
''' : '';

    final system = '''
You are a Socratic reading companion helping $userName read "$bookTitle" by $bookAuthor.
They are $progress through the book (page $currentPage of $totalPages).

Your style:
• Ask one thoughtful question at the end of every response
• Never summarise or spoil content beyond the current page
• Ground responses in actual text — quote briefly when it illuminates a point
• Responses under 150 words unless the user asks to go deeper
• Warm, intellectually curious tone — like a brilliant friend who just read the same book
• Support English, Russian, and Uzbek — reply in the language the user writes in

$contextBlock$callbackBlock''';

    return _message(
      systemPrompt: system,
      messages: history.map((m) => {'role': m.role, 'content': m.content}).toList(),
      model: ApiKeys.claudeModel,
      maxTokens: 600,
    );
  }

  // ── Curriculum Generation ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateCurriculum(String topic) async {
    const schema = '''{
  "title": "string",
  "description": "string",
  "levels": [
    {
      "number": 1,
      "title": "string",
      "description": "string",
      "book_title": "string",
      "book_author": "string",
      "color_hex": "#58CC02",
      "icon_emoji": "📖",
      "lessons": [
        {"id": "l1_1", "title": "string", "number": 1},
        {"id": "l1_2", "title": "string", "number": 2},
        {"id": "l1_3", "title": "string", "number": 3}
      ]
    }
  ]
}''';

    final prompt = '''
Create a 4-level reading curriculum for someone who wants to master: "$topic"

Rules:
• Pick 4 landmark books — order from foundational → advanced
• Each book = one level, exactly 3 lessons each
• Lesson titles must be specific and evocative (not "Chapter 1")
• Colors (use exactly in order): #58CC02, #1CB0F6, #CE82FF, #FF9600
• Emojis (use exactly in order): 📖, 🔬, 🧠, 🚀
• Make it feel like a Netflix series — every lesson title should create curiosity

Return ONLY valid JSON matching this schema, no markdown fences:
$schema''';

    final raw = await _message(
      systemPrompt:
          'You are an expert curriculum designer. Return only valid JSON — no markdown, no explanation.',
      messages: [
        {'role': 'user', 'content': prompt}
      ],
      model: ApiKeys.claudeModel,
      maxTokens: 1500,
      temperature: 0.4,
    );

    // Strip markdown fences if Claude adds them anyway
    final cleaned = raw
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    return json.decode(cleaned) as Map<String, dynamic>;
  }

  // ── Lesson Content Generation ──────────────────────────────────────────────

  Future<Map<String, dynamic>> generateLessonContent({
    required String lessonTitle,
    required String bookTitle,
    required String bookAuthor,
    required String topic,
    required int lessonNumber,
  }) async {
    final prompt = '''
Generate interactive lesson content for a reading app lesson.

Book: "$bookTitle" by $bookAuthor
Topic: $topic
Lesson: "$lessonTitle" (lesson $lessonNumber)

Return ONLY valid JSON:
{
  "read": {
    "content": "300-400 word engaging explanation of the key ideas from this lesson. Use markdown: **bold**, *italic*, > blockquotes for key quotes. Make it feel like a brilliant tutor explaining the concept."
  },
  "quiz": {
    "question": "Thought-provoking multiple-choice question about this lesson",
    "options": ["A) ...", "B) ...", "C) ...", "D) ..."],
    "correctIndex": 0,
    "explanation": "2 sentences explaining why the correct answer is right and what it means"
  },
  "chat": {
    "prompt": "Opening Socratic question to spark discussion about this lesson's core idea"
  }
}''';

    final raw = await _message(
      systemPrompt:
          'You are an expert educator creating engaging lesson content. Return only valid JSON.',
      messages: [
        {'role': 'user', 'content': prompt}
      ],
      model: ApiKeys.claudeModel,
      maxTokens: 1200,
      temperature: 0.5,
    );

    final cleaned = raw
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    return json.decode(cleaned) as Map<String, dynamic>;
  }

  // ── Episode Metadata ───────────────────────────────────────────────────────

  Future<EpisodeMetadata> generateEpisodeMetadata({
    required String bookTitle,
    required String author,
    required String chunkContent,
    required int chunkNumber,
    required int totalChunks,
  }) async {
    final truncated = chunkContent.length > 2000
        ? '${chunkContent.substring(0, 2000)}… [truncated]'
        : chunkContent;

    final prompt = '''
Book: "$bookTitle" by $author — excerpt $chunkNumber of $totalChunks

Excerpt:
$truncated

Return ONLY valid JSON:
{
  "episodeTitle": "5 words max, evocative like a TV episode title",
  "keyIdea": "one sentence — the core thing happening or being argued",
  "preview": "2 sentences teasing this section without spoiling beyond it",
  "difficulty": "light|moderate|dense",
  "estimatedMinutes": <number 5-45>
}''';

    try {
      final raw = await _message(
        systemPrompt: 'You create engaging Netflix-style reading episode metadata. Return only valid JSON.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        model: ApiKeys.claudeHaikuModel, // fast + cheap for metadata
        maxTokens: 300,
        temperature: 0.3,
      );
      final cleaned = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();
      final data = json.decode(cleaned) as Map<String, dynamic>;
      return EpisodeMetadata(
        episodeTitle: data['episodeTitle'] ?? 'Episode $chunkNumber',
        keyIdea: data['keyIdea'] ?? 'Key insight from this section',
        preview: data['preview'] ?? 'Continue your reading journey',
        difficulty: _parseDifficulty(data['difficulty']),
        estimatedMinutes: data['estimatedMinutes'] ?? 20,
      );
    } catch (e) {
      debugPrint('⚠️ Episode metadata fallback: $e');
      return EpisodeMetadata(
        episodeTitle: 'Episode $chunkNumber',
        keyIdea: 'Continue your reading journey',
        preview: 'Another exciting section of the book',
        difficulty: Difficulty.moderate,
        estimatedMinutes: 20,
      );
    }
  }

  // ── Quiz Generation ────────────────────────────────────────────────────────

  Future<List<QuizQuestion>> generateQuiz({
    required String bookTitle,
    required String content,
    required int startPage,
    required int endPage,
  }) async {
    final prompt = '''
Book: "$bookTitle" — pages $startPage–$endPage

Content:
${content.length > 1500 ? '${content.substring(0, 1500)}…' : content}

Generate exactly 3 comprehension questions. Return ONLY valid JSON:
{
  "questions": [
    {"question": "...", "type": "open-ended", "hint": "Think about…"},
    {"question": "...", "type": "theme", "hint": null},
    {"question": "...", "type": "prediction", "hint": null}
  ]
}''';

    try {
      final raw = await _message(
        systemPrompt: 'You are a reading comprehension expert. Return only valid JSON.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        model: ApiKeys.claudeHaikuModel,
        maxTokens: 500,
        temperature: 0.5,
      );
      final cleaned = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();
      final data = json.decode(cleaned) as Map<String, dynamic>;
      return (data['questions'] as List)
          .map((q) => QuizQuestion(
                question: q['question'],
                type: _parseQuizType(q['type']),
                hint: q['hint'],
              ))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Quiz generation error: $e');
      rethrow;
    }
  }

  // ── Reflection Follow-up ───────────────────────────────────────────────────

  Future<String> generateReflectionFollowup({
    required String userReflection,
    required String bookTitle,
    required int currentPage,
  }) async {
    try {
      return await _message(
        systemPrompt: '''
You are a warm, intellectually engaged reading companion.
The user has shared a reflection. Respond genuinely, connect it to broader themes,
and end with a follow-up question. Under 100 words. Respond in the user's language.''',
        messages: [
          {
            'role': 'user',
            'content':
                'Book: "$bookTitle" (page $currentPage)\n\nMy reflection: "$userReflection"'
          }
        ],
        model: ApiKeys.claudeModel,
        maxTokens: 250,
      );
    } catch (e) {
      return "That's a great observation! What do you think led to that moment?";
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Difficulty _parseDifficulty(dynamic val) {
    switch ('$val'.toLowerCase()) {
      case 'light':
        return Difficulty.light;
      case 'dense':
        return Difficulty.dense;
      default:
        return Difficulty.moderate;
    }
  }

  QuizType _parseQuizType(dynamic val) {
    switch ('$val'.toLowerCase()) {
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

// ─── Shared data classes (re-exported from openai_service) ────────────────────

class ChatMessage {
  final String role;
  final String content;
  ChatMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
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
  QuizQuestion({required this.question, required this.type, this.hint});
}

enum QuizType { openEnded, theme, prediction }
