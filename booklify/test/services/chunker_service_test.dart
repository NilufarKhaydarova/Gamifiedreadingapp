import 'package:booklify/data/models/book.dart';
import 'package:booklify/data/services/chunker_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _words(int n, [String w = 'word']) => List.filled(n, w).join(' ');

void main() {
  final chunker = SmartChunkerService();

  group('SmartChunkerService.createReadingPlan', () {
    test('empty content gives an empty plan', () async {
      expect(await chunker.createReadingPlan(content: '   ', totalDays: 7),
          isEmpty);
    });

    test('splits on chapter headings when there are more than 3', () async {
      final content = List.generate(
          6, (i) => 'Chapter ${i + 1}\n\n${_words(50)}.').join('\n\n');
      final plan = await chunker.createReadingPlan(content: content,
          totalDays: 6);
      expect(plan, hasLength(6));
      expect(plan.map((c) => c.dayNumber), [1, 2, 3, 4, 5, 6]);
      expect(plan.first.episodeTitle, 'Chapter 1');
      expect(plan.every((c) => c.subChunks.isNotEmpty), isTrue);
    });

    test('groups chapters when there are more chapters than days', () async {
      final content = List.generate(
          10, (i) => 'Chapter ${i + 1}\n\n${_words(20)}.').join('\n\n');
      final plan = await chunker.createReadingPlan(content: content,
          totalDays: 5);
      expect(plan, hasLength(5));
      expect(plan.first.subChunks, hasLength(2));
    });

    test('never creates more days than there are text chunks', () async {
      final plan = await chunker.createReadingPlan(
          content: 'Just one short paragraph.', totalDays: 30);
      expect(plan, hasLength(1));
    });

    test('falls back to ~1000-word paragraph chunks without chapters',
        () async {
      final content = List.generate(6, (_) => '${_words(500)}.').join('\n\n');
      final plan = await chunker.createReadingPlan(content: content,
          totalDays: 3);
      expect(plan, hasLength(3));
      expect(plan.every((c) => c.estimatedMinutes > 0), isTrue);
      expect(plan.first.preview.length, lessThanOrEqualTo(201));
    });

    test('rates long, varied sentences as dense and short ones as light',
        () async {
      final dense = await chunker.createReadingPlan(
          content: 'Epistemological considerations notwithstanding, '
              'phenomenological hermeneutics necessitates interdisciplinary '
              'methodological reconceptualisation.',
          totalDays: 1);
      final light = await chunker.createReadingPlan(
          content: 'The cat sat. The cat ran. The dog sat. The dog ran. '
              'The cat sat. The dog ran.',
          totalDays: 1);
      expect(dense.single.difficulty, Difficulty.dense);
      expect(light.single.difficulty, Difficulty.light);
    });

    test('keeps text that appears before the first chapter heading',
        () async {
      final chapters = List.generate(
          5, (i) => 'Chapter ${i + 1}\n\n${_words(20)}.').join('\n\n');
      final content = 'PREFACE: an important introduction.\n\n$chapters';
      final plan = await chunker.createReadingPlan(content: content,
          totalDays: 5);
      final allText = plan
          .expand((c) => c.subChunks)
          .map((s) => s.content)
          .join('\n');
      expect(allText, contains('PREFACE'));
    }, skip: 'BUG: _splitByNaturalBreaks starts at the first "Chapter N" '
        'match, so any preface/introduction text is silently dropped.');
  });
}
