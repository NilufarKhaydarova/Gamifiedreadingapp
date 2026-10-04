import 'package:booklify/data/models/book.dart';
import 'package:booklify/data/services/chunker_service.dart';
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

  test('BUG: text before the first chapter (preface / intro) is dropped', () async {
    final content = 'PREFACE-TEXT about this book.\n\n${_chapters(5)}';
    final plan = await chunker.createReadingPlan(content: content, totalDays: 5);
    expect(_allText(plan), contains('PREFACE-TEXT'));
  }, skip: 'Known bug: SmartChunkerService drops text before the first chapter heading');

  test('BUG: Windows line endings (\\r\\n) put the whole book into one day', () async {
    final content = _paragraphs(20).replaceAll('\n', '\r\n');
    final plan = await chunker.createReadingPlan(content: content, totalDays: 4);
    expect(plan.length, greaterThan(1));
  }, skip: 'Known bug: paragraph split only recognises "\\n\\n"');

  test('BUG: chunk offsets do not point at the chunk text in the original book', () async {
    // Offsets are used to give the AI chat the passage the reader is on.
    final content = 'Intro line.\n\n${_chapters(5)}';
    final plan = await chunker.createReadingPlan(content: content, totalDays: 5);
    final day2 = plan[1];
    expect(content.substring(day2.startOffset, day2.endOffset), startsWith('Chapter 2'));
  }, skip: 'Known bug: offsets are computed from re-joined text, not the original');
}
