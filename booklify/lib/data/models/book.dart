class Book {
  final String id;
  final String title;
  final String author;
  final int totalPages;
  final String content;
  final DateTime uploadDate;
  final String? coverUrl;
  final String? openLibraryKey;
  final List<String>? genres;
  final String? language;
  final String? description;
  final int? publishYear;
  final List<BookChunk> chunks;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.totalPages,
    required this.content,
    required this.uploadDate,
    this.coverUrl,
    this.openLibraryKey,
    this.genres,
    this.language,
    this.description,
    this.publishYear,
    this.chunks = const [],
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? totalPages,
    String? content,
    DateTime? uploadDate,
    String? coverUrl,
    String? openLibraryKey,
    List<String>? genres,
    String? language,
    String? description,
    int? publishYear,
    List<BookChunk>? chunks,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      content: content ?? this.content,
      uploadDate: uploadDate ?? this.uploadDate,
      coverUrl: coverUrl ?? this.coverUrl,
      openLibraryKey: openLibraryKey ?? this.openLibraryKey,
      genres: genres ?? this.genres,
      language: language ?? this.language,
      description: description ?? this.description,
      publishYear: publishYear ?? this.publishYear,
      chunks: chunks ?? this.chunks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'totalPages': totalPages,
      'content': content,
      'uploadDate': uploadDate.toIso8601String(),
      'coverUrl': coverUrl,
      'openLibraryKey': openLibraryKey,
      'genres': genres,
      'language': language,
      'description': description,
      'publishYear': publishYear,
      'chunks': chunks.map((c) => c.toJson()).toList(),
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      totalPages: json['totalPages'] as int,
      content: json['content'] as String,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      coverUrl: json['coverUrl'] as String?,
      openLibraryKey: json['openLibraryKey'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      language: json['language'] as String?,
      description: json['description'] as String?,
      publishYear: json['publishYear'] as int?,
      chunks: (json['chunks'] as List<dynamic>?)
              ?.map((c) => BookChunk.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BookChunk {
  final String id;
  final int dayNumber;
  final String episodeTitle;
  final String keyIdea;
  final String preview;
  final Difficulty difficulty;
  final int estimatedMinutes;
  final int startOffset;
  final int endOffset;
  final bool completed;
  final DateTime? completedDate;
  final List<SubChunk> subChunks;

  BookChunk({
    required this.id,
    required this.dayNumber,
    required this.episodeTitle,
    required this.keyIdea,
    required this.preview,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.startOffset,
    required this.endOffset,
    this.completed = false,
    this.completedDate,
    this.subChunks = const [],
  });

  BookChunk copyWith({
    String? id,
    int? dayNumber,
    String? episodeTitle,
    String? keyIdea,
    String? preview,
    Difficulty? difficulty,
    int? estimatedMinutes,
    int? startOffset,
    int? endOffset,
    bool? completed,
    DateTime? completedDate,
    List<SubChunk>? subChunks,
  }) {
    return BookChunk(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      keyIdea: keyIdea ?? this.keyIdea,
      preview: preview ?? this.preview,
      difficulty: difficulty ?? this.difficulty,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      completed: completed ?? this.completed,
      completedDate: completedDate ?? this.completedDate,
      subChunks: subChunks ?? this.subChunks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayNumber': dayNumber,
      'episodeTitle': episodeTitle,
      'keyIdea': keyIdea,
      'preview': preview,
      'difficulty': difficulty.name,
      'estimatedMinutes': estimatedMinutes,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'completed': completed,
      'completedDate': completedDate?.toIso8601String(),
      'subChunks': subChunks.map((c) => c.toJson()).toList(),
    };
  }

  factory BookChunk.fromJson(Map<String, dynamic> json) {
    return BookChunk(
      id: json['id'] as String,
      dayNumber: json['dayNumber'] as int,
      episodeTitle: json['episodeTitle'] as String,
      keyIdea: json['keyIdea'] as String,
      preview: json['preview'] as String,
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => Difficulty.moderate,
      ),
      estimatedMinutes: json['estimatedMinutes'] as int,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
      completed: json['completed'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      subChunks: (json['subChunks'] as List<dynamic>?)
              ?.map((c) => SubChunk.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SubChunk {
  final String id;
  final String content;
  final ChunkType type;
  final int? wordCount;

  SubChunk({
    required this.id,
    required this.content,
    required this.type,
    this.wordCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'wordCount': wordCount,
    };
  }

  factory SubChunk.fromJson(Map<String, dynamic> json) {
    return SubChunk(
      id: json['id'] as String,
      content: json['content'] as String,
      type: ChunkType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChunkType.section,
      ),
      wordCount: json['wordCount'] as int?,
    );
  }
}

enum Difficulty { light, moderate, dense }

enum ChunkType { chapter, section, paragraph }