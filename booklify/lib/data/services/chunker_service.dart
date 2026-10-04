import 'package:uuid/uuid.dart';
import '../../core/utils/text_spans.dart';
import '../models/book.dart';

// Internal text chunk used during splitting
class _TextChunk {
  final String content;
  final int startIndex;
  final int endIndex;

  _TextChunk({
    required this.content,
    required this.startIndex,
    required this.endIndex,
  });
}

class SmartChunkerService {
  SmartChunkerService();

  // Main chunking function - creates reading plan from book content.
  Future<List<BookChunk>> createReadingPlan({
    required String content,
    required int totalDays,
    String bookTitle = 'Book',
    String author = '',
  }) async {
    if (content.trim().isEmpty) return [];

    // Step 1: Split content into natural breaks
    final textChunks = _splitByNaturalBreaks(content);

    // Step 2: Group text chunks into daily sessions, spread evenly so the
    // reader gets the number of days they asked for (up to one per unit).
    final effectiveDays = totalDays.clamp(1, textChunks.length.clamp(1, 365));
    final bounds = evenGroupBounds(textChunks.length, effectiveDays);
    final dailyGroups = <List<_TextChunk>>[
      for (int i = 0; i + 1 < bounds.length; i++)
        textChunks.sublist(bounds[i], bounds[i + 1]),
    ];

    // Step 3: Build BookChunks
    final enrichedChunks = <BookChunk>[];
    int dayNumber = 1;

    for (final dayChunks in dailyGroups) {
      // Offsets point into the original content (used to fetch the passage).
      final startOffset = dayChunks.first.startIndex;
      final endOffset = dayChunks.last.endIndex;
      final combinedContent =
          normalizeLineEndings(content.substring(startOffset, endOffset));

      // Sub-chunks
      final subChunks = dayChunks.asMap().entries.map((entry) {
        return SubChunk(
          id: const Uuid().v4(),
          content: entry.value.content,
          type: _getChunkType(entry.value.content),
          wordCount: countWords(entry.value.content),
        );
      }).toList();

      // Content analysis for difficulty
      final analysis = _analyzeContent(combinedContent);

      // Fallback metadata (ClaudeService.generateSmartChunks handles AI enrichment)
      final episodeTitle = _generateFallbackTitle(combinedContent, dayNumber);
      const keyIdea = '';
      final preview = combinedContent.length > 200
          ? '${combinedContent.substring(0, 200)}…'
          : combinedContent;

      enrichedChunks.add(BookChunk(
        id: 'day-$dayNumber',
        dayNumber: dayNumber,
        episodeTitle: episodeTitle,
        keyIdea: keyIdea,
        preview: preview,
        difficulty: analysis.difficulty,
        estimatedMinutes: (analysis.estimatedReadingTime / 60).ceil(),
        startOffset: startOffset,
        endOffset: endOffset,
        subChunks: subChunks,
        completed: false,
      ));

      dayNumber++;
    }

    return enrichedChunks;
  }

  String _generateFallbackTitle(String content, int dayNumber) {
    // Try to extract chapter heading
    final chapterMatch =
        RegExp(r'(Chapter\s+[\d\w]+)', caseSensitive: false).firstMatch(content);
    if (chapterMatch != null) {
      return chapterMatch.group(1) ?? 'Day $dayNumber';
    }
    // First meaningful line
    final firstLine = content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.length > 10, orElse: () => '');
    if (firstLine.isNotEmpty && firstLine.length < 60) {
      return firstLine;
    }
    return 'Day $dayNumber';
  }

  // Split content by natural breaks (chapters, sections, paragraphs).
  // Every chunk keeps its real offsets into [content].
  List<_TextChunk> _splitByNaturalBreaks(String content) {
    final chapterPatterns = [
      RegExp(r'Chapter \d+', caseSensitive: false),
      RegExp(r'Chapter [IVXLCDM]+', caseSensitive: false),
      RegExp(r'CHAPTER \d+', caseSensitive: false),
      RegExp(r'第.+章'),
    ];

    for (final pattern in chapterPatterns) {
      final matches = pattern.allMatches(content).toList();
      if (matches.length > 3) {
        final chunks = <_TextChunk>[];
        for (int i = 0; i < matches.length; i++) {
          // Text before the first heading (title page, preface, intro) is
          // read together with the first chapter rather than dropped.
          final start = i == 0 ? 0 : matches[i].start;
          final end =
              i < matches.length - 1 ? matches[i + 1].start : content.length;
          _addChunk(chunks, content, start, end);
        }
        return chunks;
      }
    }

    return _splitIntoParagraphChunks(content);
  }

  void _addChunk(List<_TextChunk> chunks, String content, int start, int end) {
    final range = trimRange(content, start, end);
    if (range == null) return;
    chunks.add(_TextChunk(
      content: normalizeLineEndings(range.of(content)),
      startIndex: range.start,
      endIndex: range.end,
    ));
  }

  /// Groups paragraphs into ~1000-word chunks.
  List<_TextChunk> _splitIntoParagraphChunks(String content) {
    const wordsPerChunk = 1000;
    final chunks = <_TextChunk>[];
    final paragraphs = splitParagraphs(content);

    int? groupStart;
    int groupEnd = 0;
    int wordCount = 0;

    for (final para in paragraphs) {
      final paraWords = countWords(para.of(content));
      if (groupStart != null && wordCount + paraWords > wordsPerChunk) {
        _addChunk(chunks, content, groupStart, groupEnd);
        groupStart = null;
        wordCount = 0;
      }
      groupStart ??= para.start;
      groupEnd = para.end;
      wordCount += paraWords;
    }
    if (groupStart != null) _addChunk(chunks, content, groupStart, groupEnd);

    return chunks;
  }

  ChunkType _getChunkType(String content) {
    final words = countWords(content);
    if (RegExp(r'Chapter \d+').hasMatch(content) && words > 500) {
      return ChunkType.chapter;
    }
    if (words > 500) return ChunkType.section;
    return ChunkType.paragraph;
  }

  _ContentAnalysis _analyzeContent(String content) {
    final words = content.split(RegExp(r'\s+'));
    final sentences =
        content.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty);
    final sentenceCount = sentences.length.clamp(1, 10000);

    final avgSentenceLength = words.length / sentenceCount;
    final avgWordLength =
        words.isEmpty ? 4.0 : words.join('').length / words.length;
    final uniqueWords = words.map((w) => w.toLowerCase()).toSet();
    final lexicalDiversity =
        words.isEmpty ? 0.0 : uniqueWords.length / words.length;

    Difficulty difficulty;
    if (avgSentenceLength > 25 || avgWordLength > 5.5 || lexicalDiversity > 0.72) {
      difficulty = Difficulty.dense;
    } else if (avgSentenceLength > 20 || avgWordLength > 5.0) {
      difficulty = Difficulty.moderate;
    } else {
      difficulty = Difficulty.light;
    }

    final baseWPM = 220.0;
    final adjustedWPM = difficulty == Difficulty.dense
        ? baseWPM * 0.7
        : difficulty == Difficulty.light
            ? baseWPM * 1.3
            : baseWPM;
    final estimatedSeconds =
        ((words.length / adjustedWPM) * 60).ceil();

    return _ContentAnalysis(
      difficulty: difficulty,
      estimatedReadingTime: estimatedSeconds,
    );
  }
}

class _ContentAnalysis {
  final Difficulty difficulty;
  final int estimatedReadingTime; // in seconds

  _ContentAnalysis({
    required this.difficulty,
    required this.estimatedReadingTime,
  });
}

// Public-facing content analysis (kept for backward compatibility)
class ContentAnalysis {
  final Difficulty difficulty;
  final double avgSentenceLength;
  final double avgWordLength;
  final double lexicalDiversity;
  final int wordCount;
  final int estimatedReadingTime;

  ContentAnalysis({
    required this.difficulty,
    required this.avgSentenceLength,
    required this.avgWordLength,
    required this.lexicalDiversity,
    required this.wordCount,
    required this.estimatedReadingTime,
  });
}
