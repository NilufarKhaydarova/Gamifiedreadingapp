import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/book.dart';
import '../../data/models/curriculum.dart';
import '../../data/services/curriculum_service.dart';
import '../../data/services/database_service.dart';
import 'auth_provider.dart';

// ─── Service Provider ─────────────────────────────────────────────────────────

final curriculumServiceProvider = Provider<CurriculumService>((ref) {
  return CurriculumService(); // Uses Claude when ANTHROPIC_API_KEY is set
});

// ─── Curriculum Notifier ──────────────────────────────────────────────────────

class CurriculumNotifier extends AsyncNotifier<Curriculum?> {
  DatabaseService get _db => ref.read(databaseServiceProvider);
  CurriculumService get _service => ref.read(curriculumServiceProvider);

  @override
  Future<Curriculum?> build() async {
    final user = ref.watch(authUserProvider);
    if (user == null) return null;
    return _load(user.id);
  }

  Future<Curriculum?> _load(String userId) async {
    final data = await _db.getCurriculum(userId);
    if (data == null) return null;
    return Curriculum.fromJson(
      data,
      id: data['id'] as String?,
      userId: userId,
      topic: data['topic'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'] as String)
          : null,
      totalXP: data['total_xp'] as int?,
      streak: data['streak'] as int?,
    );
  }

  // Generate a brand-new curriculum for a given topic
  Future<void> generate(String topic) async {
    final user = ref.read(authUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final curriculum = await _service.generateStructure(topic, user.id);
      await _db.saveCurriculum(
        curriculum.toJson(),
        userId: user.id,
        topic: topic,
        totalXP: 0,
        streak: 0,
      );
      return curriculum;
    });
  }

  // Build curriculum directly from a book's reading plan (no AI call needed).
  // Each chunk → one lesson; every 7 lessons → one level (week).
  // Quiz/chat content is still fetched lazily when the user opens the lesson.
  Future<void> generateFromBook(Book book) async {
    final user = ref.read(authUserProvider);
    if (user == null || book.chunks.isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      const levelSize = 7;
      const levelColors = ['#6B21A8', '#4F46E5', '#059669', '#DC2626', '#F59E0B'];
      const levelEmojis = ['📖', '🔍', '💡', '🎭', '✨'];

      final levels = <CurriculumLevel>[];

      for (int li = 0; li * levelSize < book.chunks.length; li++) {
        final start = li * levelSize;
        final end = (start + levelSize).clamp(0, book.chunks.length);
        final levelChunks = book.chunks.sublist(start, end);

        final lessons = <Lesson>[];
        for (int i = 0; i < levelChunks.length; i++) {
          final chunk = levelChunks[i];
          final isFirst = li == 0 && i == 0;

          // Pull real chapter text.
          final rawText = chunk.subChunks.isNotEmpty
              ? chunk.subChunks.map((s) => s.content).join('\n\n')
              : (book.content.isNotEmpty &&
                      chunk.endOffset > chunk.startOffset)
                  ? book.content.substring(
                      chunk.startOffset.clamp(0, book.content.length),
                      chunk.endOffset.clamp(0, book.content.length))
                  : chunk.keyIdea;

          final steps = _buildInterleavedSteps(chunk, rawText);

          lessons.add(Lesson(
            id: 'lesson_${chunk.id}',
            title: 'Day ${chunk.dayNumber}',
            number: chunk.dayNumber,
            steps: steps,
            isUnlocked: isFirst || chunk.completed,
            isCompleted: chunk.completed,
            xpReward: 50,
          ));
        }

        levels.add(CurriculumLevel(
          number: li + 1,
          title: 'Week ${li + 1}',
          description: 'Days ${start + 1}–$end of ${book.chunks.length}',
          bookTitle: book.title,
          bookAuthor: book.author,
          colorHex: levelColors[li % levelColors.length],
          iconEmoji: levelEmojis[li % levelEmojis.length],
          lessons: lessons,
          isUnlocked: li == 0 || levels.isNotEmpty && levels[li - 1].isCompleted,
        ));
      }

      final curriculum = Curriculum(
        id: const Uuid().v4(),
        userId: user.id,
        topic: book.title,
        title: book.title,
        description: 'by ${book.author}',
        levels: levels,
        createdAt: DateTime.now(),
        totalXP: 0,
        streak: 0,
      );

      await _db.saveCurriculum(
        curriculum.toJson(),
        userId: user.id,
        topic: book.title,
        totalXP: 0,
        streak: 0,
      );

      return curriculum;
    });
  }

  // ── Interleaved step builder ───────────────────────────────────────────────

  // Splits the chunk text into up to 3 sections and interleaves read + quiz steps.
  // Pattern: Read → Quiz → Read → Quiz → Read → Discuss
  List<LessonStep> _buildInterleavedSteps(BookChunk chunk, String rawText) {
    final chatPrompt = chunk.keyIdea.isNotEmpty
        ? 'Let\'s discuss: ${chunk.keyIdea}'
        : 'What themes stood out in Day ${chunk.dayNumber}?';

    final cleanedText = _cleanPdfText(rawText);

    if (cleanedText.isEmpty) {
      return [
        LessonStep(
          id: 'step_read_${chunk.id}_0',
          title: 'Day ${chunk.dayNumber}',
          type: LessonStepType.read,
          content: 'No text available for this chapter.',
          isLoaded: true,
        ),
        LessonStep(
          id: 'step_chat_${chunk.id}',
          title: 'Reflect & Discuss',
          type: LessonStepType.chat,
          chatPrompt: chatPrompt,
          isLoaded: true,
        ),
      ];
    }

    final sections = _splitIntoSections(cleanedText, 3);
    final steps = <LessonStep>[];

    for (int si = 0; si < sections.length; si++) {
      final isFirstSection = si == 0;
      final sectionTitle = isFirstSection
          ? 'Day ${chunk.dayNumber}'
          : 'Part ${si + 1} of ${sections.length}';

      // Read section
      steps.add(LessonStep(
        id: 'step_read_${chunk.id}_$si',
        title: sectionTitle,
        type: LessonStepType.read,
        content: sections[si],
        isLoaded: true,
      ));

      // Quick quiz after each section
      steps.add(LessonStep(
        id: 'step_quiz_${chunk.id}_$si',
        title: 'Quick Check',
        type: LessonStepType.quiz,
        isLoaded: false, // Generated from passage text when lesson opens
      ));
    }

    // Final discussion step
    steps.add(LessonStep(
      id: 'step_chat_${chunk.id}',
      title: 'Reflect & Discuss',
      type: LessonStepType.chat,
      chatPrompt: chatPrompt,
      isLoaded: true,
    ));

    return steps;
  }

  // Strips PDF page-header artifacts like "Crime and Punishment\n61 of 967\n"
  // and cleans up excessive whitespace from PDF extraction.
  String _cleanPdfText(String text) {
    // Remove "Title line\nX of Y\n" patterns (PDF page headers)
    var t = text.replaceAll(
        RegExp(r'^.{1,120}\n\d+ of \d+\n', multiLine: true), '');
    // Remove standalone "X of Y" page-count lines
    t = t.replaceAll(
        RegExp(r'^\d+ of \d+\s*$', multiLine: true), '');
    // Remove lines that are just a number (page numbers)
    t = t.replaceAll(RegExp(r'^\s*\d+\s*$', multiLine: true), '');
    // Collapse 3+ consecutive newlines to 2
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return t.trim();
  }

  // Splits text at paragraph breaks into `count` balanced sections.
  List<String> _splitIntoSections(String text, int count) {
    final paragraphs = text
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) return [text];
    if (paragraphs.length <= count) return paragraphs;

    final perSection = (paragraphs.length / count).ceil();
    final sections = <String>[];
    for (int i = 0; i < count; i++) {
      final start = i * perSection;
      if (start >= paragraphs.length) break;
      final end = (start + perSection).clamp(0, paragraphs.length);
      sections.add(paragraphs.sublist(start, end).join('\n\n'));
    }
    return sections;
  }

  // Load lesson content on-demand when user opens a lesson.
  // Book-driven lessons → generate quiz questions from the actual passage text.
  // Topic-driven lessons → use the original AI content generation.
  Future<void> loadLessonContent(int levelIndex, int lessonIndex) async {
    final curr = state.value;
    if (curr == null) return;

    final level = curr.levels[levelIndex];
    final lesson = level.lessons[lessonIndex];
    if (lesson.steps.isNotEmpty && lesson.steps.every((s) => s.isLoaded)) {
      return; // Already loaded
    }

    // Book-driven detection: read steps already have real passage text
    final isBookDriven = lesson.steps.any(
      (s) => s.type == LessonStepType.read && s.content.length > 80,
    );

    final loadedLesson = isBookDriven
        ? await _service.generateQuizzesFromPassages(lesson, level.bookTitle)
        : await _service.generateLessonContent(lesson, level, curr.topic);

    _updateLesson(levelIndex, lessonIndex, loadedLesson);
    await _persist();
  }

  // Mark a step complete, unlock next step/lesson/level
  Future<void> completeStep(
      int levelIndex, int lessonIndex, int stepIndex) async {
    final curr = state.value;
    if (curr == null) return;

    final levels = List<CurriculumLevel>.from(curr.levels);
    final level = levels[levelIndex];
    final lessons = List<Lesson>.from(level.lessons);
    final lesson = lessons[lessonIndex];
    final steps = List<LessonStep>.from(lesson.steps);

    // Mark this step complete
    steps[stepIndex] = steps[stepIndex].copyWith(isCompleted: true);

    // Check if all steps done → complete lesson
    bool lessonComplete = steps.every((s) => s.isCompleted);
    int xpEarned = 0;

    Lesson updatedLesson = lesson.copyWith(
      steps: steps,
      isCompleted: lessonComplete,
    );

    if (lessonComplete) {
      xpEarned = lesson.xpReward;
      // Unlock next lesson in same level
      if (lessonIndex + 1 < lessons.length) {
        final nextLesson = lessons[lessonIndex + 1];
        lessons[lessonIndex + 1] =
            nextLesson.copyWith(isUnlocked: true);
      } else if (levelIndex + 1 < levels.length) {
        // Unlock first lesson of next level
        final nextLevel = levels[levelIndex + 1];
        final nextLessons = List<Lesson>.from(nextLevel.lessons);
        if (nextLessons.isNotEmpty) {
          nextLessons[0] = nextLessons[0].copyWith(isUnlocked: true);
          levels[levelIndex + 1] = nextLevel.copyWith(
            lessons: nextLessons,
            isUnlocked: true,
          );
        }
      }
    }

    lessons[lessonIndex] = updatedLesson;
    levels[levelIndex] = level.copyWith(lessons: lessons);

    // Check if entire level complete
    final allLessonsComplete = lessons.every((l) => l.isCompleted);
    if (allLessonsComplete) {
      levels[levelIndex] = levels[levelIndex].copyWith();
    }

    final newXP = curr.totalXP + xpEarned;
    final updated = curr.copyWith(levels: levels, totalXP: newXP);
    state = AsyncData(updated);
    await _persist();
  }

  Future<void> resetCurriculum() async {
    final user = ref.read(authUserProvider);
    if (user == null) return;
    await _db.deleteCurriculum(user.id);
    state = const AsyncData(null);
  }

  void _updateLesson(int levelIndex, int lessonIndex, Lesson lesson) {
    final curr = state.value;
    if (curr == null) return;
    final levels = List<CurriculumLevel>.from(curr.levels);
    final level = levels[levelIndex];
    final lessons = List<Lesson>.from(level.lessons);
    lessons[lessonIndex] = lesson;
    levels[levelIndex] = level.copyWith(lessons: lessons);
    state = AsyncData(curr.copyWith(levels: levels));
  }

  Future<void> _persist() async {
    final curr = state.value;
    if (curr == null) return;
    final user = ref.read(authUserProvider);
    if (user == null) return;
    await _db.updateCurriculumProgress(
      curr.id,
      curr.toJson(),
      totalXP: curr.totalXP,
      streak: curr.streak,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final curriculumProvider =
    AsyncNotifierProvider<CurriculumNotifier, Curriculum?>(() {
  return CurriculumNotifier();
});

/// True if the authenticated user has an existing curriculum
final hasCurriculumProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  final db = ref.read(databaseServiceProvider);
  return db.hasCurriculum(user.id);
});

/// Convenience: current level index (0-based)
final currentLevelIndexProvider = Provider<int>((ref) {
  final curr = ref.watch(curriculumProvider).value;
  if (curr == null) return 0;
  for (int i = 0; i < curr.levels.length; i++) {
    if (!curr.levels[i].isCompleted) return i;
  }
  return curr.levels.length - 1;
});
