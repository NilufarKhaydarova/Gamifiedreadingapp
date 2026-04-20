import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum LessonStepType { read, quiz, chat }

// ─── QuizQuestion ────────────────────────────────────────────────────────────

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) {
    final correctRaw = j['correct_index'] ?? j['correct'] ?? 0;
    return QuizQuestion(
      question: j['question'] as String? ?? '',
      options: List<String>.from(j['options'] ?? []),
      correctIndex: correctRaw is int ? correctRaw : int.tryParse('$correctRaw') ?? 0,
      explanation: j['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
      };
}

// ─── LessonStep ───────────────────────────────────────────────────────────────

class LessonStep {
  final String id;
  final String title;
  final LessonStepType type;
  final String content;              // for read
  final List<QuizQuestion> questions; // for quiz
  final String chatPrompt;           // for chat
  final bool isCompleted;
  final bool isLoaded; // whether AI content has been fetched

  const LessonStep({
    required this.id,
    required this.title,
    required this.type,
    this.content = '',
    this.questions = const [],
    this.chatPrompt = '',
    this.isCompleted = false,
    this.isLoaded = false,
  });

  bool get hasContent =>
      (type == LessonStepType.read && content.isNotEmpty) ||
      (type == LessonStepType.quiz && questions.isNotEmpty) ||
      (type == LessonStepType.chat && chatPrompt.isNotEmpty);

  IconData get icon {
    switch (type) {
      case LessonStepType.read:
        return Icons.menu_book_rounded;
      case LessonStepType.quiz:
        return Icons.quiz_rounded;
      case LessonStepType.chat:
        return Icons.chat_bubble_rounded;
    }
  }

  Color get color {
    switch (type) {
      case LessonStepType.read:
        return AppColors.stepRead;
      case LessonStepType.quiz:
        return AppColors.stepQuiz;
      case LessonStepType.chat:
        return AppColors.stepChat;
    }
  }

  String get typeLabel {
    switch (type) {
      case LessonStepType.read:
        return 'Read';
      case LessonStepType.quiz:
        return 'Quiz';
      case LessonStepType.chat:
        return 'Discuss';
    }
  }

  factory LessonStep.fromJson(Map<String, dynamic> j) {
    final typeStr = j['type'] as String? ?? 'read';
    final type = LessonStepType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => LessonStepType.read,
    );
    return LessonStep(
      id: j['id'] as String? ?? 'step_${typeStr}_${DateTime.now().millisecondsSinceEpoch}',
      title: j['title'] as String? ?? '',
      type: type,
      content: j['content'] as String? ?? '',
      questions: (j['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      chatPrompt:
          j['chat_prompt'] as String? ?? j['chatPrompt'] as String? ?? '',
      isCompleted: j['is_completed'] as bool? ?? false,
      isLoaded: j['is_loaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'content': content,
        'questions': questions.map((q) => q.toJson()).toList(),
        'chat_prompt': chatPrompt,
        'is_completed': isCompleted,
        'is_loaded': isLoaded,
      };

  LessonStep copyWith({
    String? content,
    List<QuizQuestion>? questions,
    String? chatPrompt,
    bool? isCompleted,
    bool? isLoaded,
  }) =>
      LessonStep(
        id: id,
        title: title,
        type: type,
        content: content ?? this.content,
        questions: questions ?? this.questions,
        chatPrompt: chatPrompt ?? this.chatPrompt,
        isCompleted: isCompleted ?? this.isCompleted,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

// ─── Lesson ───────────────────────────────────────────────────────────────────

class Lesson {
  final String id;
  final String title;
  final int number;
  final List<LessonStep> steps;
  final bool isCompleted;
  final bool isUnlocked;
  final int xpReward;

  const Lesson({
    required this.id,
    required this.title,
    required this.number,
    required this.steps,
    this.isCompleted = false,
    this.isUnlocked = false,
    this.xpReward = 50,
  });

  double get progressPercent {
    if (steps.isEmpty) return 0;
    return steps.where((s) => s.isCompleted).length / steps.length;
  }

  bool get isInProgress =>
      isUnlocked && !isCompleted && steps.any((s) => s.isCompleted);

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String? ?? 'lesson_${j['number']}',
        title: j['title'] as String? ?? 'Lesson',
        number: j['number'] as int? ?? 0,
        steps: (j['steps'] as List<dynamic>?)
                ?.map((s) => LessonStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        isCompleted: j['is_completed'] as bool? ?? false,
        isUnlocked: j['is_unlocked'] as bool? ?? false,
        xpReward: j['xp_reward'] as int? ?? 50,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'number': number,
        'steps': steps.map((s) => s.toJson()).toList(),
        'is_completed': isCompleted,
        'is_unlocked': isUnlocked,
        'xp_reward': xpReward,
      };

  Lesson copyWith({
    List<LessonStep>? steps,
    bool? isCompleted,
    bool? isUnlocked,
  }) =>
      Lesson(
        id: id,
        title: title,
        number: number,
        steps: steps ?? this.steps,
        isCompleted: isCompleted ?? this.isCompleted,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        xpReward: xpReward,
      );
}

// ─── CurriculumLevel ─────────────────────────────────────────────────────────

class CurriculumLevel {
  final int number;
  final String title;
  final String description;
  final String bookTitle;
  final String bookAuthor;
  final String colorHex;
  final String iconEmoji;
  final List<Lesson> lessons;
  final bool isUnlocked;

  const CurriculumLevel({
    required this.number,
    required this.title,
    this.description = '',
    required this.bookTitle,
    this.bookAuthor = '',
    this.colorHex = '#58CC02',
    this.iconEmoji = '📚',
    required this.lessons,
    this.isUnlocked = false,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return AppColors.forLevel(number);
  }

  int get completedLessons => lessons.where((l) => l.isCompleted).length;
  double get progressPercent =>
      lessons.isEmpty ? 0 : completedLessons / lessons.length;
  bool get isCompleted => lessons.isNotEmpty && lessons.every((l) => l.isCompleted);

  factory CurriculumLevel.fromJson(Map<String, dynamic> j) => CurriculumLevel(
        number: j['number'] as int? ?? 1,
        title: j['title'] as String? ?? 'Level',
        description: j['description'] as String? ?? '',
        bookTitle: j['book_title'] as String? ?? j['book'] as String? ?? '',
        bookAuthor:
            j['book_author'] as String? ?? j['author'] as String? ?? '',
        colorHex:
            j['color_hex'] as String? ?? j['color'] as String? ?? '#58CC02',
        iconEmoji:
            j['icon_emoji'] as String? ?? j['icon'] as String? ?? '📚',
        lessons: (j['lessons'] as List<dynamic>?)
                ?.map((l) => Lesson.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        isUnlocked: j['is_unlocked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'title': title,
        'description': description,
        'book_title': bookTitle,
        'book_author': bookAuthor,
        'color_hex': colorHex,
        'icon_emoji': iconEmoji,
        'lessons': lessons.map((l) => l.toJson()).toList(),
        'is_unlocked': isUnlocked,
      };

  CurriculumLevel copyWith({
    List<Lesson>? lessons,
    bool? isUnlocked,
  }) =>
      CurriculumLevel(
        number: number,
        title: title,
        description: description,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        colorHex: colorHex,
        iconEmoji: iconEmoji,
        lessons: lessons ?? this.lessons,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );
}

// ─── Curriculum ───────────────────────────────────────────────────────────────

class Curriculum {
  final String id;
  final String userId;
  final String topic;
  final String title;
  final String description;
  final List<CurriculumLevel> levels;
  final DateTime createdAt;
  final int totalXP;
  final int streak;

  const Curriculum({
    required this.id,
    required this.userId,
    required this.topic,
    required this.title,
    this.description = '',
    required this.levels,
    required this.createdAt,
    this.totalXP = 0,
    this.streak = 0,
  });

  int get totalLessons =>
      levels.fold(0, (sum, l) => sum + l.lessons.length);
  int get completedLessons =>
      levels.fold(0, (sum, l) => sum + l.completedLessons);
  double get overallProgress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;
  int get currentLevelNumber {
    for (final level in levels) {
      if (!level.isCompleted) return level.number;
    }
    return levels.isEmpty ? 1 : levels.last.number;
  }

  factory Curriculum.fromJson(
    Map<String, dynamic> j, {
    String? id,
    String? userId,
    String? topic,
    DateTime? createdAt,
    int? totalXP,
    int? streak,
  }) =>
      Curriculum(
        id: id ?? j['id'] as String? ?? '',
        userId: userId ?? j['user_id'] as String? ?? '',
        topic: topic ?? j['topic'] as String? ?? '',
        title: j['title'] as String? ?? 'My Curriculum',
        description: j['description'] as String? ?? '',
        levels: (j['levels'] as List<dynamic>?)
                ?.map((l) =>
                    CurriculumLevel.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: createdAt ?? DateTime.now(),
        totalXP: totalXP ?? j['total_xp'] as int? ?? 0,
        streak: streak ?? j['streak'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'topic': topic,
        'title': title,
        'description': description,
        'levels': levels.map((l) => l.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'total_xp': totalXP,
        'streak': streak,
      };

  Curriculum copyWith({
    List<CurriculumLevel>? levels,
    int? totalXP,
    int? streak,
  }) =>
      Curriculum(
        id: id,
        userId: userId,
        topic: topic,
        title: title,
        description: description,
        levels: levels ?? this.levels,
        createdAt: createdAt,
        totalXP: totalXP ?? this.totalXP,
        streak: streak ?? this.streak,
      );
}
