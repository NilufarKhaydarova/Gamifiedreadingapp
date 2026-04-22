import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import 'database_service.dart';
import 'openai_service.dart';

// ─── Adaptive RAG Service ─────────────────────────────────────────────────────
// Builds rich, personalized context for AI calls by combining:
//   1. Current book passage (what the user is reading now)
//   2. The user's highlights in this book (what caught their attention)
//   3. Their AI question history (what they needed clarification on)
//   4. Reading pace analytics (where they slowed down)
//   5. Semantic search via OpenAI embeddings (if key available)
//   6. Adaptive reader profile (who they are as a reader)
//
// This context is injected into every AI call so the companion
// adapts to the individual rather than giving generic responses.

class AdaptiveRagService {
  final DatabaseService _db;
  final OpenAIService _openai = OpenAIService();

  AdaptiveRagService(this._db);

  // ─── Build full adaptive context ──────────────────────────────────────────

  Future<AdaptiveContext> buildContext({
    required String userId,
    required Book book,
    required BookChunk chunk,
  }) async {
    // Run all fetches in parallel
    final results = await Future.wait([
      _db.getHighlights(userId, book.id),
      _db.getAiInteractions(userId, book.id),
      _db.getReadingAnalytics(userId),
      _db.getUserReadingProfile(userId),
    ]);

    final highlights = results[0] as List<Map<String, dynamic>>;
    final interactions = results[1] as List<Map<String, dynamic>>;
    final analytics = results[2] as List<Map<String, dynamic>>;
    final profile = results[3] as Map<String, dynamic>;

    // 1. Current passage
    final passage = _extractPassage(book, chunk);

    // 2. Prior highlights summary
    final highlightSummary = _summarizeHighlights(highlights);

    // 3. AI question patterns
    final aiPatterns = _summarizeAiInteractions(interactions);

    // 4. Pace notes for this book
    final paceNotes = _summarizePace(analytics, book.id);

    // 5. Reader profile (human-readable)
    final profileSummary = _profileSummary(profile);

    // 6. Semantic context (if OpenAI key available) — top passages similar to recent questions
    String semanticPassage = '';
    try {
      if (interactions.isNotEmpty) {
        final lastQuestion = interactions.first['question'] as String? ?? '';
        if (lastQuestion.isNotEmpty) {
          semanticPassage =
              await _semanticSearch(lastQuestion, book);
        }
      }
    } catch (e) {
      debugPrint('Semantic search skipped: $e');
    }

    return AdaptiveContext(
      currentPassage: passage,
      highlightSummary: highlightSummary,
      aiPatterns: aiPatterns,
      paceNotes: paceNotes,
      profileSummary: profileSummary,
      semanticPassage: semanticPassage,
    );
  }

  // ─── Update profile after a reading session ───────────────────────────────

  Future<void> updateProfileAfterSession({
    required String userId,
    required String bookId,
    required String bookTitle,
    required List<String> sessionHighlights,
    required List<String> sessionAiQuestions,
    required int sessionWpm,
    required double scrollCompletion,
  }) async {
    final existing = await _db.getUserReadingProfile(userId);

    // Extract keywords from highlights
    final highlightKeywords = _extractKeywords(sessionHighlights.join(' '));
    final questionKeywords = _extractKeywords(sessionAiQuestions.join(' '));

    // Merge into profile
    final currentHighlightThemes =
        List<String>.from(existing['highlightThemes'] ?? []);
    final currentAiTopics =
        List<String>.from(existing['frequentAiTopics'] ?? []);
    final currentBooks =
        List<String>.from(existing['booksEngaged'] ?? []);

    // Add new keywords (deduplicated, max 20 each)
    for (final kw in highlightKeywords) {
      if (!currentHighlightThemes.contains(kw)) {
        currentHighlightThemes.insert(0, kw);
      }
    }
    for (final kw in questionKeywords) {
      if (!currentAiTopics.contains(kw)) {
        currentAiTopics.insert(0, kw);
      }
    }
    if (!currentBooks.contains(bookTitle)) {
      currentBooks.add(bookTitle);
    }

    // Update average WPM (running average)
    final prevWpm = (existing['avgWpm'] as num?)?.toInt() ?? 0;
    final newAvgWpm = prevWpm == 0
        ? sessionWpm
        : ((prevWpm + sessionWpm) / 2).round();

    // Determine depth preference from AI interaction frequency
    final totalQs = (existing['totalAiQuestions'] as num?)?.toInt() ?? 0;
    final totalH = (existing['totalHighlights'] as num?)?.toInt() ?? 0;
    final newTotalQs = totalQs + sessionAiQuestions.length;
    final newTotalH = totalH + sessionHighlights.length;

    String depth = 'moderate';
    if (newTotalQs > 20) depth = 'deep';
    if (newTotalQs < 5 && newTotalH < 5) depth = 'light';

    final updated = {
      'avgWpm': newAvgWpm,
      'totalHighlights': newTotalH,
      'totalAiQuestions': newTotalQs,
      'highlightThemes': currentHighlightThemes.take(20).toList(),
      'frequentAiTopics': currentAiTopics.take(20).toList(),
      'booksEngaged': currentBooks,
      'preferredDepth': depth,
      'lastScrollCompletion': scrollCompletion,
      'lastUpdated': DateTime.now().toIso8601String().split('T').first,
    };

    await _db.updateUserReadingProfile(userId, updated);
  }

  // ─── Semantic search via embeddings ──────────────────────────────────────

  Future<String> _semanticSearch(String query, Book book) async {
    if (book.chunks.isEmpty || book.content.isEmpty) return '';

    // Get accessible chunks (completed + current)
    final accessible = book.chunks
        .where((c) => c.completed || (!c.completed && c.isAccessible(book.chunks)))
        .take(10)
        .toList();
    if (accessible.isEmpty) return '';

    // Embed the query
    final queryVec = await _openai.generateEmbedding(query);

    // Embed each chunk's key idea (cheap, short strings)
    final chunkTexts =
        accessible.map((c) => c.keyIdea.isNotEmpty ? c.keyIdea : c.episodeTitle).toList();
    final chunkVecs = await _openai.generateEmbeddings(chunkTexts);

    // Rank by cosine similarity
    double bestScore = -1;
    int bestIdx = 0;
    for (int i = 0; i < chunkVecs.length; i++) {
      final score = _cosine(queryVec, chunkVecs[i]);
      if (score > bestScore) {
        bestScore = score;
        bestIdx = i;
      }
    }

    // Return top passage text
    final bestChunk = accessible[bestIdx];
    final text = bestChunk.subChunks.isNotEmpty
        ? bestChunk.subChunks.first.content
        : _extractPassageFromOffsets(book.content, bestChunk.startOffset, bestChunk.endOffset);

    return text.length > 800 ? '${text.substring(0, 800)}…' : text;
  }

  double _cosine(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    return denom == 0 ? 0 : dot / denom;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _extractPassage(Book book, BookChunk chunk) {
    if (chunk.subChunks.isNotEmpty) {
      final text = chunk.subChunks.map((s) => s.content).join('\n\n');
      return text.length > 2500 ? '${text.substring(0, 2500)}…' : text;
    }
    if (book.content.isNotEmpty) {
      return _extractPassageFromOffsets(
          book.content, chunk.startOffset, chunk.endOffset);
    }
    return '';
  }

  String _extractPassageFromOffsets(String content, int start, int end) {
    if (content.isEmpty) return '';
    final s = start.clamp(0, content.length);
    final e = end.clamp(s, content.length);
    if (e <= s) return '';
    final slice = content.substring(s, e);
    return slice.length > 2500 ? '${slice.substring(0, 2500)}…' : slice;
  }

  String _summarizeHighlights(List<Map<String, dynamic>> highlights) {
    if (highlights.isEmpty) return '';
    final texts = highlights.take(8).map((h) {
      final text = h['text'] as String? ?? '';
      return text.length > 120 ? '"${text.substring(0, 120)}…"' : '"$text"';
    }).join('\n');
    return 'Reader\'s highlights (${highlights.length} total):\n$texts';
  }

  String _summarizeAiInteractions(List<Map<String, dynamic>> interactions) {
    if (interactions.isEmpty) return '';
    final recent = interactions.take(5);
    final questions =
        recent.map((i) => '• ${i['question'] as String? ?? ''}').join('\n');
    // Extract topics from tags
    final allTags = <String>{};
    for (final i in interactions.take(15)) {
      try {
        final tags = json.decode(i['topic_tags'] as String? ?? '[]') as List;
        allTags.addAll(tags.cast<String>());
      } catch (_) {}
    }
    final tagSummary =
        allTags.isNotEmpty ? 'Recurring topics: ${allTags.take(6).join(', ')}' : '';
    return 'Recent questions:\n$questions\n$tagSummary';
  }

  String _summarizePace(List<Map<String, dynamic>> analytics, String bookId) {
    final bookAnalytics = analytics.where((a) => a['book_id'] == bookId).toList();
    if (bookAnalytics.isEmpty) return '';

    final wpms = bookAnalytics.map((a) => (a['wpm'] as num?)?.toInt() ?? 0).where((w) => w > 0).toList();
    if (wpms.isEmpty) return '';

    final avgWpm = wpms.reduce((a, b) => a + b) ~/ wpms.length;
    final minWpm = wpms.reduce(math.min);
    final maxWpm = wpms.reduce(math.max);

    return 'Reading pace: avg ${avgWpm}wpm (range $minWpm–$maxWpm). '
        'Sessions: ${bookAnalytics.length}. '
        '${avgWpm < 150 ? "Reader tends to slow down — likely processing deeply." : avgWpm > 280 ? "Fast reader — may benefit from more challenging questions." : "Moderate pace."}';
  }

  String _profileSummary(Map<String, dynamic> profile) {
    final themes =
        (profile['highlightThemes'] as List?)?.cast<String>() ?? [];
    final topics =
        (profile['frequentAiTopics'] as List?)?.cast<String>() ?? [];
    final depth = profile['preferredDepth'] as String? ?? 'unknown';
    final wpm = (profile['avgWpm'] as num?)?.toInt() ?? 0;
    final books =
        (profile['booksEngaged'] as List?)?.cast<String>() ?? [];

    if (themes.isEmpty && topics.isEmpty) return '';

    final parts = <String>[];
    if (themes.isNotEmpty) {
      parts.add('Themes this reader is drawn to: ${themes.take(5).join(', ')}');
    }
    if (topics.isNotEmpty) {
      parts.add('AI help frequently requested on: ${topics.take(5).join(', ')}');
    }
    if (wpm > 0) parts.add('Average reading speed: ${wpm}wpm');
    if (depth != 'unknown') parts.add('Engagement depth: $depth');
    if (books.isNotEmpty) parts.add('Books engaged: ${books.join(', ')}');

    return parts.join('. ');
  }

  // Extract meaningful keywords (filter stopwords, min 4 chars)
  static const _stopwords = {
    'that', 'this', 'with', 'from', 'have', 'been', 'they', 'what',
    'when', 'where', 'which', 'there', 'their', 'would', 'could',
    'should', 'about', 'into', 'then', 'than', 'your', 'more',
    'just', 'like', 'also', 'does', 'make', 'time', 'very',
  };

  List<String> _extractKeywords(String text) {
    if (text.isEmpty) return [];
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4 && !_stopwords.contains(w))
        .toList();

    // Frequency count
    final freq = <String, int>{};
    for (final w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }

    // Return top 5 by frequency
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }
}

// ─── Adaptive Context ─────────────────────────────────────────────────────────

class AdaptiveContext {
  final String currentPassage;
  final String highlightSummary;
  final String aiPatterns;
  final String paceNotes;
  final String profileSummary;
  final String semanticPassage;

  const AdaptiveContext({
    required this.currentPassage,
    required this.highlightSummary,
    required this.aiPatterns,
    required this.paceNotes,
    required this.profileSummary,
    required this.semanticPassage,
  });

  /// Formats everything into a structured XML block for the AI system prompt.
  String toPromptString() {
    final parts = <String>[];

    if (currentPassage.isNotEmpty) {
      parts.add('<current_passage>\n$currentPassage\n</current_passage>');
    }
    if (highlightSummary.isNotEmpty) {
      parts.add('<reader_highlights>\n$highlightSummary\n</reader_highlights>');
    }
    if (aiPatterns.isNotEmpty) {
      parts.add('<ai_interaction_history>\n$aiPatterns\n</ai_interaction_history>');
    }
    if (paceNotes.isNotEmpty) {
      parts.add('<reading_pace>\n$paceNotes\n</reading_pace>');
    }
    if (semanticPassage.isNotEmpty) {
      parts.add('<semantically_relevant_passage>\n$semanticPassage\n</semantically_relevant_passage>');
    }
    if (profileSummary.isNotEmpty) {
      parts.add('<reader_profile>\n$profileSummary\n</reader_profile>');
    }

    return parts.join('\n\n');
  }

  bool get isEmpty =>
      currentPassage.isEmpty &&
      highlightSummary.isEmpty &&
      aiPatterns.isEmpty;
}

// ─── BookChunk extension ──────────────────────────────────────────────────────

extension ChunkAccessibility on BookChunk {
  bool isAccessible(List<BookChunk> allChunks) {
    if (dayNumber == 1) return true;
    final prev = allChunks.where((c) => c.dayNumber == dayNumber - 1);
    return prev.isNotEmpty && prev.first.completed;
  }
}
