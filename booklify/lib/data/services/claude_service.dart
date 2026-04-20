import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../../core/constants/api_keys.dart';

// ─── Claude Service ───────────────────────────────────────────────────────────
// Primary AI for all reasoning, Socratic chat, Smart Chunking, and quizzes.
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
      receiveTimeout: const Duration(seconds: 120),
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
      debugPrint('Claude API error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  // ── Smart Chunking Engine ──────────────────────────────────────────────────
  // PROSPECTIVE: restructures the book before reading into daily episodes.
  // Each episode has: title, key idea, preview, difficulty, glossary,
  // learning objectives, connection note to previous episode.

  Future<List<BookChunk>> generateSmartChunks({
    required String bookTitle,
    required String bookAuthor,
    required String bookContent, // actual book text
    required int totalDays,
    required String userGoal, // 'thesis' | 'knowledge' | 'exam' | 'personal'
    required int minutesPerDay,
  }) async {
    // Trim content to fit context window (~80k chars max)
    final contentSnippet = bookContent.length > 80000
        ? bookContent.substring(0, 80000)
        : bookContent;

    final goalDescriptions = {
      'thesis': 'academic research for a thesis — emphasise citations, arguments, epistemology, and scholarly rigour',
      'knowledge': 'deep intellectual understanding — emphasise concepts, mental models, and connections',
      'exam': 'exam preparation — emphasise key facts, definitions, comparisons, and testable material',
      'personal': 'personal growth — emphasise actionable insights, reflections, and practical application',
    };
    final goalDesc = goalDescriptions[userGoal] ??
        'deep understanding of the material';

    final prompt = '''
You are the Smart Chunking Engine for Booklify, a gamified reading app.

Book: "$bookTitle" by $bookAuthor
User goal: $goalDesc
Schedule: $totalDays days × $minutesPerDay minutes/day
Reading pace: ~${minutesPerDay * 200} words per day (200 wpm average)

Book text (first 80 000 chars):
---
$contentSnippet
---

TASK: Restructure this book into exactly $totalDays daily reading episodes BEFORE the user starts reading.
This is PROSPECTIVE planning — create a structured learning path from the full content.

For each episode, decide:
- Which section/pages of the book belong to this day
- A Netflix-style episode title (5 words max, evocative)
- The single most important idea (keyIdea)
- A teaser preview (2 sentences, no spoilers beyond this episode)
- Difficulty: "light" | "moderate" | "dense"
- estimatedMinutes: realistic reading time
- glossary: 3-6 dense/technical terms from this episode with concise definitions (dictionary-style, 1 sentence each)
- learningObjectives: 2-3 bullet points — what the reader will understand after this episode
- connectionNote: for day > 1, one sentence connecting this episode to the previous one (empty string for day 1)

Difficulty guidance:
- "light": narrative, anecdotal, easy prose
- "moderate": analytical, some technical terms, requires focus
- "dense": abstract theory, heavy argumentation, requires re-reading

Return ONLY valid JSON — no markdown fences, no comments:
{
  "chunks": [
    {
      "dayNumber": 1,
      "episodeTitle": "string (max 5 words)",
      "keyIdea": "string (1 sentence)",
      "preview": "string (2 sentences)",
      "difficulty": "light|moderate|dense",
      "estimatedMinutes": 20,
      "startOffset": 0,
      "endOffset": 5000,
      "glossary": {
        "term1": "definition1",
        "term2": "definition2"
      },
      "learningObjectives": ["objective1", "objective2"],
      "connectionNote": ""
    }
  ]
}

Important:
- startOffset and endOffset are character positions in the full book text
- Distribute content evenly across all $totalDays days
- Make each episode title feel like must-read TV
- Glossary terms should be the most challenging words/concepts in that section
- Learning objectives should be concrete and measurable''';

    try {
      final raw = await _message(
        systemPrompt:
            'You are an expert curriculum designer and literary educator. '
            'Return ONLY valid JSON — no markdown fences, no explanation.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        model: ApiKeys.claudeModel,
        maxTokens: 8000,
        temperature: 0.4,
      );

      final cleaned = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final data = json.decode(cleaned) as Map<String, dynamic>;
      final chunksList = data['chunks'] as List;
      final totalLen = bookContent.length;

      final chunks = chunksList.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value as Map<String, dynamic>;

        // Parse glossary
        final rawGlossary = c['glossary'] as Map<String, dynamic>? ?? {};
        final glossary =
            rawGlossary.map((k, v) => MapEntry(k, v.toString()));

        // Parse learning objectives → store as SubChunk with content
        final objectives =
            (c['learningObjectives'] as List?)?.cast<String>() ?? [];
        final connectionNote = c['connectionNote'] as String? ?? '';

        // Build rich sub-chunks
        final subChunks = <SubChunk>[];
        if (objectives.isNotEmpty) {
          subChunks.add(SubChunk(
            id: 'day${c['dayNumber']}-objectives',
            content: objectives.map((o) => '• $o').join('\n'),
            type: ChunkType.section,
            wordCount: objectives.join(' ').split(' ').length,
          ));
        }
        if (connectionNote.isNotEmpty) {
          subChunks.add(SubChunk(
            id: 'day${c['dayNumber']}-connection',
            content: connectionNote,
            type: ChunkType.paragraph,
            wordCount: connectionNote.split(' ').length,
          ));
        }

        // Compute offsets — use AI-provided if valid, otherwise distribute evenly
        final chunkSize = (totalLen / totalDays).ceil();
        final aiStart = (c['startOffset'] as num?)?.toInt();
        final aiEnd = (c['endOffset'] as num?)?.toInt();
        final startOffset =
            (aiStart != null && aiStart >= 0 && aiStart < totalLen)
                ? aiStart
                : i * chunkSize;
        final endOffset =
            (aiEnd != null && aiEnd > startOffset && aiEnd <= totalLen)
                ? aiEnd
                : math.min((i + 1) * chunkSize, totalLen);

        return BookChunk(
          id: 'day-${c['dayNumber']}',
          dayNumber: (c['dayNumber'] as num).toInt(),
          episodeTitle: c['episodeTitle'] as String? ?? 'Day ${i + 1}',
          keyIdea: c['keyIdea'] as String? ?? '',
          preview: c['preview'] as String? ?? '',
          difficulty: _parseDifficulty(c['difficulty']),
          estimatedMinutes:
              (c['estimatedMinutes'] as num?)?.toInt() ?? minutesPerDay,
          startOffset: startOffset,
          endOffset: endOffset,
          completed: false,
          subChunks: subChunks,
          glossary: glossary,
        );
      }).toList();

      debugPrint(
          'Smart chunks generated: ${chunks.length} episodes for "$bookTitle"');
      return chunks;
    } catch (e) {
      debugPrint('generateSmartChunks error: $e — falling back to text split');
      // Fallback: split text evenly
      return _fallbackChunksFromText(
          bookContent, bookTitle, bookAuthor, totalDays, minutesPerDay);
    }
  }

  // ── Fallback: evenly split text when AI fails ──────────────────────────────

  List<BookChunk> _fallbackChunksFromText(
    String content,
    String title,
    String author,
    int days,
    int minutesPerDay,
  ) {
    final chunkSize = (content.length / days).ceil();
    return List.generate(days, (i) {
      final start = i * chunkSize;
      final end = math.min((i + 1) * chunkSize, content.length);
      final excerpt = content.substring(start, math.min(start + 200, end));
      final preview =
          excerpt.length > 120 ? '${excerpt.substring(0, 120)}…' : excerpt;
      return BookChunk(
        id: 'day-${i + 1}',
        dayNumber: i + 1,
        episodeTitle: 'Episode ${i + 1}',
        keyIdea: 'Continue reading "$title"',
        preview: preview,
        difficulty: Difficulty.moderate,
        estimatedMinutes: minutesPerDay,
        startOffset: start,
        endOffset: end,
        completed: false,
        subChunks: [],
        glossary: const {},
      );
    });
  }

  // ── generateReadingPlan — backward-compatible fallback ────────────────────
  // When a user adds a book by title only (no actual text), Claude generates
  // an educational 7-day guide based on its knowledge of the book.

  Future<List<BookChunk>> generateReadingPlan({
    required String title,
    required String author,
    int totalDays = 7,
  }) async {
    // Delegate to generateSmartChunks with empty content
    // This triggers the AI to use its parametric knowledge of the book.
    final prompt = '''
Create a $totalDays-day guided reading plan for "$title" by $author.
You do NOT have the book text — use your knowledge of the book.

For each day, provide a structured reading guide that helps readers engage deeply.

Return ONLY valid JSON:
{
  "chunks": [
    {
      "dayNumber": 1,
      "episodeTitle": "5 words max, Netflix-style episode title",
      "keyIdea": "One sentence — the core idea or theme for this section",
      "preview": "2 sentences teasing what readers will explore today",
      "difficulty": "light",
      "estimatedMinutes": 20,
      "startOffset": 0,
      "endOffset": 1000,
      "glossary": {
        "term": "definition"
      },
      "learningObjectives": ["objective 1", "objective 2"],
      "connectionNote": "",
      "sections": [
        {
          "title": "Context & Overview",
          "content": "300-400 words of engaging content: historical context, what happens in this section, key characters introduced. Use markdown: **bold** for key terms, > for important quotes or ideas.",
          "type": "chapter"
        },
        {
          "title": "Themes & Analysis",
          "content": "250-300 words diving into the literary themes, symbolism, and deeper meaning in this section.",
          "type": "section"
        },
        {
          "title": "Reflect & Discuss",
          "content": "3-4 thought-provoking discussion questions formatted as:\\n\\n**Question 1:** ...\\n\\n**Question 2:** ...\\n\\n**Question 3:** ...",
          "type": "paragraph"
        }
      ]
    }
  ]
}

Difficulty: days 1-2 = "light", days 3-5 = "moderate", days 6+ = "dense"
estimatedMinutes: 15-25 per day
Make each day feel like a compelling episode — create anticipation for the next.''';

    try {
      final raw = await _message(
        systemPrompt:
            'You are an expert literary educator creating an immersive reading guide. '
            'Return only valid JSON.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        model: ApiKeys.claudeModel,
        maxTokens: 6000,
        temperature: 0.5,
      );

      final cleaned = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final data = json.decode(cleaned) as Map<String, dynamic>;
      final chunks = (data['chunks'] as List).asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value as Map<String, dynamic>;

        final sections = (c['sections'] as List?) ?? [];
        final subChunks = sections.asMap().entries.map((se) {
          final sc = se.value as Map<String, dynamic>;
          return SubChunk(
            id: 'day${c['dayNumber']}-section${se.key}',
            content: sc['content'] as String? ?? '',
            type: _parseChunkType(sc['type']),
            wordCount: (sc['content'] as String? ?? '').split(' ').length,
          );
        }).toList();

        final rawGlossary = c['glossary'] as Map<String, dynamic>? ?? {};
        final glossary =
            rawGlossary.map((k, v) => MapEntry(k, v.toString()));

        return BookChunk(
          id: 'day-${c['dayNumber']}',
          dayNumber: (c['dayNumber'] as num).toInt(),
          episodeTitle: c['episodeTitle'] as String? ?? 'Day ${i + 1}',
          keyIdea: c['keyIdea'] as String? ?? '',
          preview: c['preview'] as String? ?? '',
          difficulty: _parseDifficulty(c['difficulty']),
          estimatedMinutes:
              (c['estimatedMinutes'] as num?)?.toInt() ?? 20,
          startOffset: i * 1000,
          endOffset: (i + 1) * 1000,
          completed: false,
          subChunks: subChunks,
          glossary: glossary,
        );
      }).toList();

      debugPrint(
          'Generated ${chunks.length}-day reading plan for "$title"');
      return chunks;
    } catch (e) {
      debugPrint('generateReadingPlan error: $e');
      // Return a minimal fallback so the app never crashes
      return List.generate(
        totalDays,
        (i) => BookChunk(
          id: 'day-${i + 1}',
          dayNumber: i + 1,
          episodeTitle: 'Day ${i + 1}',
          keyIdea: 'Exploring "$title"',
          preview: 'Your reading journey continues.',
          difficulty: Difficulty.moderate,
          estimatedMinutes: 20,
          startOffset: i * 1000,
          endOffset: (i + 1) * 1000,
          subChunks: [
            SubChunk(
              id: 'day${i + 1}-section0',
              content:
                  '## Day ${i + 1} Reading Guide\n\nContinue reading '
                  '"$title" by $author.\n\nReflect on what you\'ve read '
                  'so far and consider the themes being developed.',
              type: ChunkType.section,
              wordCount: 30,
            ),
          ],
          glossary: const {},
        ),
      );
    }
  }

  // ── Local RAG: keyword-based context retrieval ─────────────────────────────

  /// Simplified local RAG: keyword search over accessible chunks.
  /// Only searches up to [currentDay] — never reveals future content.
  String retrieveLocalContext({
    required String query,
    required List<BookChunk> chunks,
    required int currentDay,
    int topK = 3,
  }) {
    final accessibleChunks =
        chunks.where((c) => c.dayNumber <= currentDay).toList();
    if (accessibleChunks.isEmpty) return '';

    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toSet();

    if (queryWords.isEmpty) return '';

    // Score each chunk by keyword overlap in title + keyIdea + preview + subchunk content
    final scored = accessibleChunks.map((chunk) {
      final text =
          '${chunk.episodeTitle} ${chunk.keyIdea} ${chunk.preview} '
          '${chunk.subChunks.map((s) => s.content).join(' ')}'
              .toLowerCase();
      final score =
          queryWords.fold<int>(0, (acc, w) => acc + (text.contains(w) ? 1 : 0));
      return _ScoredChunk(chunk: chunk, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final top = scored.take(topK).where((s) => s.score > 0).toList();
    if (top.isEmpty) return '';

    final buf = StringBuffer();
    for (final s in top) {
      final c = s.chunk;
      buf.writeln('--- Day ${c.dayNumber}: ${c.episodeTitle} ---');
      buf.writeln(c.keyIdea);
      if (c.subChunks.isNotEmpty) {
        final excerpt = c.subChunks.first.content;
        buf.writeln(
            excerpt.length > 400 ? '${excerpt.substring(0, 400)}…' : excerpt);
      }
      buf.writeln();
    }
    return buf.toString().trim();
  }

  // ── Cross-episode callbacks ────────────────────────────────────────────────

  /// Find past completed episodes thematically connected to the current chunk.
  String retrieveCrossEpisodeCallbacks({
    required BookChunk currentChunk,
    required List<BookChunk> completedChunks,
    int topK = 2,
  }) {
    if (completedChunks.isEmpty) return '';

    // Build a keyword set from the current chunk
    final currentWords =
        '${currentChunk.episodeTitle} ${currentChunk.keyIdea} ${currentChunk.preview}'
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((w) => w.length > 4)
            .toSet();

    // Also include glossary terms as high-signal keywords
    for (final term in currentChunk.glossary.keys) {
      currentWords.addAll(term.toLowerCase().split(RegExp(r'\s+')));
    }

    if (currentWords.isEmpty) return '';

    final scored = completedChunks
        .where((c) => c.id != currentChunk.id)
        .map((chunk) {
      final text =
          '${chunk.episodeTitle} ${chunk.keyIdea} ${chunk.preview} '
          '${chunk.glossary.keys.join(' ')}'
              .toLowerCase();
      final score = currentWords
          .fold<int>(0, (acc, w) => acc + (text.contains(w) ? 1 : 0));
      return _ScoredChunk(chunk: chunk, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final top = scored.take(topK).where((s) => s.score > 0).toList();
    if (top.isEmpty) return '';

    final buf = StringBuffer();
    buf.writeln('Related themes from earlier episodes:');
    for (final s in top) {
      buf.writeln(
          '• Day ${s.chunk.dayNumber} "${s.chunk.episodeTitle}": ${s.chunk.keyIdea}');
    }
    return buf.toString().trim();
  }

  // ── Socratic Reading Companion ─────────────────────────────────────────────
  // RAG-grounded. NEVER provides summaries — only asks Socratic questions.
  // Responds in the user's language (EN / RU / UZ).

  Future<String> socraticChat({
    required String bookTitle,
    required String bookAuthor,
    required int currentPage,
    required int totalPages,
    required String userName,
    required List<ChatMessage> history,
    String? ragContext, // injected book passages (from retrieveLocalContext)
    String? callbackContext, // cross-episode narrative callbacks
  }) async {
    final progress = totalPages > 0
        ? '${(currentPage / totalPages * 100).round()}%'
        : 'unknown';

    final contextBlock = ragContext != null && ragContext.isNotEmpty
        ? '''
<retrieved_context>
$ragContext
</retrieved_context>
'''
        : '';

    final callbackBlock = callbackContext != null && callbackContext.isNotEmpty
        ? '''
<callbacks>
$callbackContext
</callbacks>
'''
        : '';

    final system = '''
You are a Socratic reading companion helping $userName read "$bookTitle" by $bookAuthor.
They are $progress through the book (page $currentPage of $totalPages).

CRITICAL RULES — never break these:
1. ASK QUESTIONS, NEVER SUMMARISE. Every response must end with a thought-provoking question.
2. Never reveal or hint at content beyond the reader's current position (page $currentPage).
3. Ground your responses in the actual text — reference passages when relevant.
4. One question per response — do not ask multiple questions at once.
5. Responses under 150 words unless the user explicitly asks to go deeper.
6. NEVER produce a summary, recap, or synopsis of the book — not even if asked.
7. If the user asks for a summary, redirect with a Socratic question instead.

Language: Detect the user's language from their message. Reply in the SAME language.
Supported languages: English, Russian (Русский), Uzbek (O'zbek).

Tone: Warm, intellectually curious — like a brilliant friend who just finished the same chapter.
Style: Short, incisive. Use the reader's own words back at them when possible.

$contextBlock$callbackBlock''';

    return _message(
      systemPrompt: system,
      messages:
          history.map((m) => {'role': m.role, 'content': m.content}).toList(),
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
        systemPrompt:
            'You create engaging Netflix-style reading episode metadata. Return only valid JSON.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        model: ApiKeys.claudeHaikuModel,
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
      debugPrint('Episode metadata fallback: $e');
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
        systemPrompt:
            'You are a reading comprehension expert. Return only valid JSON.',
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
      debugPrint('Quiz generation error: $e');
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

// ── Internal helper ────────────────────────────────────────────────────────────

class _ScoredChunk {
  final BookChunk chunk;
  final int score;
  _ScoredChunk({required this.chunk, required this.score});
}

// ─── Shared data classes ──────────────────────────────────────────────────────

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
