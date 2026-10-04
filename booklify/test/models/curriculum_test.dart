import 'package:booklify/data/models/curriculum.dart';
import 'package:flutter_test/flutter_test.dart';

LessonStep _step(String id, {bool done = false}) => LessonStep(
    id: id, title: id, type: LessonStepType.read, content: 'x',
    isCompleted: done);

Lesson _lesson(int n, {bool done = false, List<LessonStep>? steps}) => Lesson(
      id: 'l$n',
      title: 'Lesson $n',
      number: n,
      steps: steps ?? [_step('s$n', done: done)],
      isCompleted: done,
      isUnlocked: true,
    );

void main() {
  group('Curriculum model', () {
    final curriculum = Curriculum(
      id: 'c1',
      userId: 'u1',
      topic: 'Stoicism',
      title: 'Stoicism 101',
      createdAt: DateTime(2026, 1, 1),
      totalXP: 50,
      levels: [
        CurriculumLevel(
            number: 1,
            title: 'L1',
            bookTitle: 'B',
            lessons: [_lesson(1, done: true), _lesson(2, done: true)],
            isUnlocked: true),
        CurriculumLevel(
            number: 2, title: 'L2', bookTitle: 'B', lessons: [_lesson(3), _lesson(4)]),
      ],
    );

    test('aggregate progress getters', () {
      expect(curriculum.totalLessons, 4);
      expect(curriculum.completedLessons, 2);
      expect(curriculum.overallProgress, 0.5);
      expect(curriculum.currentLevelNumber, 2);
      expect(curriculum.levels.first.isCompleted, isTrue);
      expect(curriculum.levels.last.progressPercent, 0);
    });

    test('Lesson progress / in-progress flags', () {
      final l = _lesson(1, steps: [_step('a', done: true), _step('b')]);
      expect(l.progressPercent, 0.5);
      expect(l.isInProgress, isTrue);
    });

    test('LessonStep.hasContent depends on step type', () {
      expect(const LessonStep(id: 'q', title: 'q', type: LessonStepType.quiz)
          .hasContent, isFalse);
      expect(const LessonStep(id: 'c', title: 'c', type: LessonStepType.chat,
          chatPrompt: 'Why?').hasContent, isTrue);
    });

    test('JSON round-trip', () {
      final back = Curriculum.fromJson(curriculum.toJson(),
          createdAt: curriculum.createdAt);
      expect(back.toJson(), curriculum.toJson());
    });

    test('fromJson tolerates sparse AI output', () {
      final c = Curriculum.fromJson({
        'levels': [
          {
            'lessons': [
              {
                'steps': [
                  {'type': 'quiz', 'questions': []},
                  {'type': 'unknown'}
                ]
              }
            ]
          }
        ]
      });
      expect(c.title, 'My Curriculum');
      final steps = c.levels.single.lessons.single.steps;
      expect(steps.first.type, LessonStepType.quiz);
      expect(steps.last.type, LessonStepType.read);
    });
  });
}
