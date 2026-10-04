import 'package:booklify/data/models/book.dart';
import 'package:booklify/data/services/chunker_service.dart';
import 'package:booklify/presentation/providers/book_provider.dart' show chunksFromText;
import 'package:flutter_test/flutter_test.dart';

String _chapters(int n, {int wordsEach = 50}) => List.generate(
      n,
      (i) => 'Chapter ${i + 1}\n\n${List.filled(wordsEach, 'word${i + 1}').join(' ')}.',
    ).join('\n\n');

String _paragraphs(int n, {int wordsEach = 200}) => List.generate(
      n,
      (i) => List.filled(wordsEach, 'p$i').join(' '),
    ).join('\n\n');

String _allText(List<BookChunk> chunks) =>
    chunks.expand((c) => c.subChunks).map((s) => s.content).join('\n\n');

void main() {
  final chunker = SmartChunkerService();

  test('empty content gives no reading plan', () async {
    expect(await chunker.createReadingPlan(content: '  ', totalDays: 7), isEmpty);
  });

  test('splits a book with chapters into one day per chapter', () async {
    final plan = await chunker.createReadingPlan(content: _chapters(10), totalDays: 10);
    expect(plan, hasLength(10));
    expect(plan.map((c) => c.dayNumber), List.generate(10, (i) => i + 1));
    expect(plan.first.episodeTitle, 'Chapter 1');
    expect(plan.last.episodeTitle, 'Chapter 10');
    expect(plan.every((c) => c.subChunks.isNotEmpty), isTrue);
  });

  test('groups chapters when there are fewer days than chapters', () async {
    final plan = await chunker.createReadingPlan(content: _chapters(12), totalDays: 4);
    expect(plan, hasLength(4));
    expect(plan.every((c) => c.subChunks.length == 3), isTrue);
  });

  test('never creates more days than there are text units', () async {
    final plan = await chunker.createReadingPlan(content: _chapters(5), totalDays: 30);
    expect(plan, hasLength(5));
  });

  test('falls back to ~1000-word paragraph groups when there are no chapters', () async {
    // 20 paragraphs × 200 words = 4000 words → 4 units of 1000 words
    final plan = await chunker.createReadingPlan(content: _paragraphs(20), totalDays: 4);
    expect(plan, hasLength(4));
  });

  test('every day gets a reading-time estimate and a preview', () async {
    final plan = await chunker.createReadingPlan(content: _chapters(6, wordsEach: 400), totalDays: 6);
    for (final day in plan) {
      expect(day.estimatedMinutes, greaterThan(0));
      expect(day.preview, isNotEmpty);
      expect(day.completed, isFalse);
    }
  });

  test('all chapter text is kept across the plan', () async {
    final content = _chapters(8);
    final plan = await chunker.createReadingPlan(content: content, totalDays: 4);
    for (var i = 1; i <= 8; i++) {
      expect(_allText(plan), contains('word$i'));
    }
  });

  test('text before the first chapter (preface / intro) is read on day 1', () async {
    final content = 'PREFACE-TEXT about this book.\n\n${_chapters(5)}';
    final plan = await chunker.createReadingPlan(content: content, totalDays: 5);
    expect(plan, hasLength(5));
    expect(plan.first.subChunks.first.content, startsWith('PREFACE-TEXT'));
    expect(plan.first.episodeTitle, 'Chapter 1');
  });

  test('Windows line endings (\\r\\n) are split into days like normal text', () async {
    final content = _paragraphs(20).replaceAll('\n', '\r\n');
    final plan = await chunker.createReadingPlan(content: content, totalDays: 4);
    expect(plan, hasLength(4));
    expect(_allText(plan), isNot(contains('\r')));
  });

  test('paragraphs separated by single line breaks are still split', () async {
    final content = _paragraphs(20).replaceAll('\n\n', '\n');
    final plan = await chunker.createReadingPlan(content: content, totalDays: 4);
    expect(plan, hasLength(4));
  });

  test('gives the number of days asked for when chapters do not divide evenly', () async {
    final plan = await chunker.createReadingPlan(content: _chapters(12), totalDays: 5);
    expect(plan, hasLength(5));
    expect(plan.map((d) => d.subChunks.length), [2, 2, 3, 2, 3]);
  });

  group('chunk offsets point at the day\'s text in the original book', () {
    void expectOffsetsMatch(String content, List<BookChunk> plan) {
      for (final day in plan) {
        final slice = content.substring(day.startOffset, day.endOffset).replaceAll('\r\n', '\n');
        expect(slice, startsWith(day.subChunks.first.content), reason: 'day ${day.dayNumber}');
        expect(slice, endsWith(day.subChunks.last.content), reason: 'day ${day.dayNumber}');
      }
    }

    test('chapter books', () async {
      final content = 'Intro line.\n\n${_chapters(5)}';
      final plan = await chunker.createReadingPlan(content: content, totalDays: 5);
      expect(content.substring(plan[1].startOffset, plan[1].endOffset), startsWith('Chapter 2'));
      expectOffsetsMatch(content, plan);
    });

    test('paragraph books with Windows line endings', () async {
      final content = _paragraphs(20).replaceAll('\n', '\r\n');
      expectOffsetsMatch(content, await chunker.createReadingPlan(content: content, totalDays: 4));
    });
  });

  group('chunksFromText (book provider, no AI)', () {
    final text = List.generate(14, (i) => 'Paragraph $i ${'w ' * 30}').join('\n\n');

    test('splits paragraphs into the requested days', () {
      final plan = chunksFromText(text, days: 7);
      expect(plan, hasLength(7));
      expect(plan.every((d) => d.subChunks.length == 2), isTrue);
    });

    test('keeps every paragraph and real offsets', () {
      final plan = chunksFromText(text, days: 5);
      expect(plan.expand((d) => d.subChunks).length, 14);
      for (final day in plan) {
        expect(text.substring(day.startOffset, day.endOffset), startsWith(day.subChunks.first.content));
      }
    });

    test('handles Windows and single line breaks', () {
      expect(chunksFromText(text.replaceAll('\n', '\r\n'), days: 7), hasLength(7));
      expect(chunksFromText(text.replaceAll('\n\n', '\n'), days: 7), hasLength(7));
    });

    test('blank text gives no days (used to recurse forever)', () {
      expect(chunksFromText('   \n \n  '), isEmpty);
    });

    test('never more days than paragraphs', () {
      expect(chunksFromText('One.\n\nTwo.', days: 7), hasLength(2));
    });
  });
}
