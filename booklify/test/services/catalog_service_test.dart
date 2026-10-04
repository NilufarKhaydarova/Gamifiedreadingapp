import 'package:booklify/data/services/catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogService', () {
    test('catalog is non-empty and titles are unique', () {
      final titles = CatalogService.allBooks.map((b) => b.title).toList();
      expect(titles, isNotEmpty);
      expect(titles.toSet().length, titles.length);
    });

    test('every book has sane metadata', () {
      for (final b in CatalogService.allBooks) {
        expect(b.author, isNotEmpty, reason: b.title);
        expect(b.pages, greaterThan(0), reason: b.title);
        expect(['Accessible', 'Moderate', 'Challenging'],
            contains(b.difficulty), reason: b.title);
      }
    });

    test('genres are unique and byGenre partitions the catalog', () {
      final genres = CatalogService.genres;
      expect(genres.toSet().length, genres.length);
      final total = genres.fold<int>(
          0, (n, g) => n + CatalogService.byGenre(g).length);
      expect(total, CatalogService.allBooks.length);
    });

    test('search is case-insensitive over title/author/genre', () {
      final first = CatalogService.allBooks.first;
      expect(CatalogService.search(first.title.toUpperCase()),
          contains(first));
      expect(CatalogService.search(first.author.toLowerCase()),
          contains(first));
      expect(CatalogService.search('   '), CatalogService.allBooks);
      expect(CatalogService.search('zzzz-no-such-book'), isEmpty);
    });
  });
}
