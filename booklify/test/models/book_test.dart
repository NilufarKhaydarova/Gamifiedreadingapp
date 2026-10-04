import 'package:booklify/data/models/book.dart';
import 'package:flutter_test/flutter_test.dart';

BookChunk _chunk(int day, {bool completed = false}) => BookChunk(
      id: 'day-$day',
      dayNumber: day,
      episodeTitle: 'Episode $day',
      keyIdea: 'Idea $day',
      preview: 'Preview $day',
      difficulty: Difficulty.dense,
      estimatedMinutes: 15,
      startOffset: 0,
      endOffset: 10,
      completed: completed,
      completedDate: completed ? DateTime(2026, 3, day) : null,
      subChunks: [
        SubChunk(id: 's$day', content: 'Text $day', type: ChunkType.chapter,
            wordCount: 2),
      ],
      glossary: {'term': 'definition'},
    );

void main() {
  group('Book / BookChunk / SubChunk', () {
    test('Book JSON round-trip keeps chunks, glossary and enums', () {
      final book = Book(
        id: 'b1',
        title: 'Crime and Punishment',
        author: 'Dostoevsky',
        totalPages: 500,
        content: 'Chapter 1 ...',
        uploadDate: DateTime(2026, 1, 2, 3, 4),
        genres: ['Fiction'],
        language: 'ru',
        publishYear: 1866,
        chunks: [_chunk(1, completed: true), _chunk(2)],
      );
      final back = Book.fromJson(book.toJson());
      expect(back.toJson(), book.toJson());
      expect(back.chunks.first.difficulty, Difficulty.dense);
      expect(back.chunks.first.subChunks.single.type, ChunkType.chapter);
      expect(back.chunks.first.glossary, {'term': 'definition'});
    });

    test('BookChunk.fromJson falls back on unknown enum values', () {
      final json = _chunk(1).toJson()
        ..['difficulty'] = 'impossible'
        ..['subChunks'] = [
          {'id': 's', 'content': 'c', 'type': 'weird'}
        ];
      final c = BookChunk.fromJson(json);
      expect(c.difficulty, Difficulty.moderate);
      expect(c.subChunks.single.type, ChunkType.section);
    });

    test('BookChunk.fromJson stringifies non-string glossary values', () {
      final json = _chunk(1).toJson()..['glossary'] = {'n': 42};
      expect(BookChunk.fromJson(json).glossary, {'n': '42'});
    });

    test('copyWith only changes the given fields', () {
      final c = _chunk(3).copyWith(completed: true);
      expect(c.completed, isTrue);
      expect(c.dayNumber, 3);
      expect(c.episodeTitle, 'Episode 3');
    });
  });
}
