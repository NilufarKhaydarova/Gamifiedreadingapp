import '../models/book.dart';
import 'openai_service.dart';

// Helper class for internal chunk representation
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
  final OpenAIService _openAI;

  SmartChunkerService(this._openAI);

  // Main chunking function - creates reading plan from book content
  Future<List<BookChunk>> createReadingPlan({
    required String bookContent,
    required int totalDays,
    required String bookTitle,
    required String author,
  }) async {
    // Step 1: Split content into natural breaks
    final textChunks = _splitByNaturalBreaks(bookContent);

    // Step 2: Group chunks into daily sessions
    final chunksPerDay = (textChunks.length / totalDays).ceil();
    final dailyChunks = <List<_TextChunk>>[];

    for (int i = 0; i < textChunks.length; i += chunksPerDay) {
      final end = (i + chunksPerDay).clamp(0, textChunks.length);
      dailyChunks.add(textChunks.sublist(i, end));
    }

    // Step 3: Enrich each day's chunks with AI metadata
    final enrichedChunks = <BookChunk>[];
    int dayNumber = 1;
    int currentOffset = 0;

    for (final dayChunks in dailyChunks) {
      final combinedContent = dayChunks
          .map((c) => c.content)
          .join('\n\n');

      final startOffset = currentOffset;
      final endOffset = currentOffset + combinedContent.length;
      currentOffset = endOffset;

      // Generate AI episode metadata
      final metadata = await _openAI.generateEpisodeMetadata(
        bookTitle: bookTitle,
        author: author,
        chunkContent: combinedContent,
        chunkNumber: dayNumber,
        totalChunks: dailyChunks.length,
      );

      // Convert text chunks to subchunks
      final subChunks = dayChunks.asMap().entries.map((entry) {
        return SubChunk(
          id: 'subchunk-$dayNumber-${entry.key}',
          content: entry.value.content,
          type: _getChunkType(entry.value.content),
          wordCount: entry.value.content.split(' ').length,
        );
      }).toList();

      // Create enriched chunk
      enrichedChunks.add(BookChunk(
        id: 'day-$dayNumber',
        dayNumber: dayNumber,
        episodeTitle: metadata.episodeTitle,
        keyIdea: metadata.keyIdea,
        preview: metadata.preview,
        difficulty: metadata.difficulty,
        estimatedMinutes: metadata.estimatedMinutes,
        startOffset: startOffset,
        endOffset: endOffset,
        subChunks: subChunks,
        completed: false,
      ));

      dayNumber++;
    }

    return enrichedChunks;
  }

  // Split content by natural breaks (chapters, sections)
  List<_TextChunk> _splitByNaturalBreaks(String content) {
    final chunks = <_TextChunk>[];

    // Try chapter splits first with multiple patterns
    final chapterPatterns = [
      RegExp(r'Chapter \d+', caseSensitive: false),
      RegExp(r'Chapter [IVXLCDM]+', caseSensitive: false),
      RegExp(r'CHAPTER \d+', caseSensitive: false),
      RegExp(r'第.+章', caseSensitive: false), // Chinese chapters
    ];

    List<Match>? chapterMatches;

    // Try each pattern until we find one with matches
    for (final pattern in chapterPatterns) {
      final matches = pattern.allMatches(content).toList();
      if (matches.length > 3) {
        chapterMatches = matches;
        break;
      }
    }

    if (chapterMatches != null && chapterMatches.length > 3) {
      // Use chapter boundaries
      for (int i = 0; i < chapterMatches.length; i++) {
        final start = chapterMatches[i].start;
        final end = i < chapterMatches.length - 1
            ? chapterMatches[i + 1].start
            : content.length;

        final chunkContent = content.substring(start, end).trim();
        if (chunkContent.isNotEmpty) {
          chunks.add(_TextChunk(
            content: chunkContent,
            startIndex: start,
            endIndex: end,
          ));
        }
      }
    } else {
      // Fall back to paragraph chunks
      chunks.addAll(_splitIntoParagraphChunks(content));
    }

    return chunks;
  }

  // Split content into paragraph-based chunks
  List<_TextChunk> _splitIntoParagraphChunks(String content) {
    final chunks = <_TextChunk>[];
    final paragraphs = content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    const wordsPerChunk = 1000;
    final chunkBuilder = StringBuffer();
    int startIndex = 0;
    int wordCount = 0;
    int chunkNum = 0;

    for (final paragraph in paragraphs) {
      final paraWords = paragraph.split(' ').length;
      final paraStart = content.indexOf(paragraph, startIndex);

      if (wordCount + paraWords > wordsPerChunk && chunkBuilder.isNotEmpty) {
        // Save current chunk
        chunks.add(_TextChunk(
          content: chunkBuilder.toString().trim(),
          startIndex: startIndex,
          endIndex: paraStart,
        ));
        chunkBuilder.clear();
        wordCount = 0;
        chunkNum++;
        startIndex = paraStart;
      }

      chunkBuilder.writeln(paragraph);
      wordCount += paraWords;
    }

    // Don't forget the last chunk
    if (chunkBuilder.isNotEmpty) {
      chunks.add(_TextChunk(
        content: chunkBuilder.toString().trim(),
        startIndex: startIndex,
        endIndex: content.length,
      ));
    }

    return chunks;
  }

  // Determine chunk type based on content
  ChunkType _getChunkType(String content) {
    // Check if it looks like a chapter
    final hasChapterHeader = RegExp(r'Chapter \d+').hasMatch(content);
    final isLongContent = content.split(' ').length > 500;

    if (hasChapterHeader && isLongContent) {
      return ChunkType.chapter;
    } else if (isLongContent) {
      return ChunkType.section;
    } else {
      return ChunkType.paragraph;
    }
  }

  // Analyze content difficulty
  Future<ContentAnalysis> analyzeContent(String content) async {
    final words = content.split(' ');
    final sentences = content.split(RegExp(r'[.!?]+'));

    // Calculate metrics
    final avgSentenceLength = words.length / sentences.length;
    final avgWordLength = words.join('').length / words.length;
    final lexicalDiversity = _calculateLexicalDiversity(words);

    // Determine difficulty
    Difficulty difficulty;
    if (avgSentenceLength > 25 || avgWordLength > 5.5 || lexicalDiversity > 0.72) {
      difficulty = Difficulty.dense;
    } else if (avgSentenceLength > 20 || avgWordLength > 5.0) {
      difficulty = Difficulty.moderate;
    } else {
      difficulty = Difficulty.light;
    }

    return ContentAnalysis(
      difficulty: difficulty,
      avgSentenceLength: avgSentenceLength,
      avgWordLength: avgWordLength,
      lexicalDiversity: lexicalDiversity,
      wordCount: words.length,
      estimatedReadingTime: _estimateReadingTime(words.length, difficulty),
    );
  }

  double _calculateLexicalDiversity(List<String> words) {
    final uniqueWords = words.toSet();
    return words.length > 0 ? uniqueWords.length / words.length : 0;
  }

  int _estimateReadingTime(int wordCount, Difficulty difficulty) {
    // Average reading speed: 200-250 words per minute
    final baseWPM = 220;
    final adjustedWPM = difficulty == Difficulty.dense
        ? baseWPM * 0.7
        : difficulty == Difficulty.light
            ? baseWPM * 1.3
            : baseWPM;

    return ((wordCount / adjustedWPM) * 60).ceil();
  }

  // Suggest handling for dense content
  List<String> getSuggestionsForDenseContent(ContentAnalysis analysis) {
    final suggestions = <String>[];

    // Check various factors
    if (analysis.avgSentenceLength > 25) {
      suggestions.add('Consider splitting this section into smaller parts');
    }

    if (analysis.wordCount > 1500) {
      suggestions.add('This is quite long - you might want to read it over 2 days');
    }

    if (analysis.lexicalDiversity > 0.75) {
      suggestions.add('This section has complex vocabulary - consider using a glossary');
    }

    return suggestions;
  }
}

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