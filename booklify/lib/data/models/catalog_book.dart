class CatalogBook {
  final String title;
  final String author;
  final String description;
  final int year;
  final String genre; // 'Philosophy' | 'Fiction' | 'Psychology' | 'Science' | 'History' | 'Economics'
  final String emoji;
  final String difficulty; // 'Accessible' | 'Moderate' | 'Challenging'
  final int pages;

  const CatalogBook({
    required this.title,
    required this.author,
    required this.description,
    required this.year,
    required this.genre,
    required this.emoji,
    required this.difficulty,
    required this.pages,
  });
}
