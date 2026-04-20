import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Load lesson content on-demand when user opens a lesson
  Future<void> loadLessonContent(int levelIndex, int lessonIndex) async {
    final curr = state.valueOrNull;
    if (curr == null) return;

    final level = curr.levels[levelIndex];
    final lesson = level.lessons[lessonIndex];
    if (lesson.steps.isNotEmpty && lesson.steps.every((s) => s.isLoaded)) {
      return; // Already loaded
    }

    final loadedLesson =
        await _service.generateLessonContent(lesson, level, curr.topic);

    _updateLesson(levelIndex, lessonIndex, loadedLesson);
    await _persist();
  }

  // Mark a step complete, unlock next step/lesson/level
  Future<void> completeStep(
      int levelIndex, int lessonIndex, int stepIndex) async {
    final curr = state.valueOrNull;
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
    final curr = state.valueOrNull;
    if (curr == null) return;
    final levels = List<CurriculumLevel>.from(curr.levels);
    final level = levels[levelIndex];
    final lessons = List<Lesson>.from(level.lessons);
    lessons[lessonIndex] = lesson;
    levels[levelIndex] = level.copyWith(lessons: lessons);
    state = AsyncData(curr.copyWith(levels: levels));
  }

  Future<void> _persist() async {
    final curr = state.valueOrNull;
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
  final curr = ref.watch(curriculumProvider).valueOrNull;
  if (curr == null) return 0;
  for (int i = 0; i < curr.levels.length; i++) {
    if (!curr.levels[i].isCompleted) return i;
  }
  return curr.levels.length - 1;
});
