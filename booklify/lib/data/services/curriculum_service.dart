import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/curriculum.dart';
import 'claude_service.dart' hide QuizQuestion;
import '../../core/constants/api_keys.dart';

class CurriculumService {
  final ClaudeService _claude = ClaudeService();

  CurriculumService();

  // ─── Generate curriculum structure (fast — no content) ────────────────────

  Future<Curriculum> generateStructure(String topic, String userId) async {
    if (ApiKeys.hasClaudeKey) {
      try {
        return await _generateWithClaude(topic, userId);
      } catch (e) {
        debugPrint('Claude curriculum generation failed: $e — using fallback');
      }
    }
    return _fallbackCurriculum(topic, userId);
  }

  Future<Curriculum> _generateWithClaude(String topic, String userId) async {
    final json = await _claude.generateCurriculum(topic);
    final curriculum = Curriculum.fromJson(
      json,
      id: const Uuid().v4(),
      userId: userId,
      topic: topic,
      createdAt: DateTime.now(),
    );
    return _initializeLocks(curriculum);
  }

  // ─── Generate lesson content (on-demand when opening a lesson) ────────────

  Future<Lesson> generateLessonContent(
    Lesson lesson,
    CurriculumLevel level,
    String topic,
  ) async {
    if (ApiKeys.hasClaudeKey) {
      try {
        return await _generateLessonWithClaude(lesson, level, topic);
      } catch (e) {
        debugPrint('Claude lesson generation failed: $e — using fallback');
      }
    }
    return _fallbackLessonContent(lesson, level, topic);
  }

  Future<Lesson> _generateLessonWithClaude(
    Lesson lesson,
    CurriculumLevel level,
    String topic,
  ) async {
    final json = await _claude.generateLessonContent(
      lessonTitle: lesson.title,
      bookTitle: level.bookTitle,
      bookAuthor: level.bookAuthor,
      topic: topic,
      lessonNumber: lesson.number,
    );

    // Map Claude's response schema to LessonStep objects
    final readContent = (json['read'] as Map?)?['content'] as String? ?? '';
    final quizData = json['quiz'] as Map? ?? {};
    final chatData = json['chat'] as Map? ?? {};

    final quizQuestion = quizData['question'] as String? ?? 'What did you learn?';
    final quizOptions = (quizData['options'] as List?)
            ?.map((o) => o.toString())
            .toList() ??
        ['Option A', 'Option B', 'Option C', 'Option D'];
    final correctIdx = quizData['correctIndex'] as int? ?? 0;
    final explanation = quizData['explanation'] as String? ?? '';

    final steps = [
      LessonStep(
        id: '${lesson.id}_read',
        title: 'Reading: ${lesson.title}',
        type: LessonStepType.read,
        content: readContent,
        isLoaded: true,
      ),
      LessonStep(
        id: '${lesson.id}_quiz',
        title: 'Knowledge Check',
        type: LessonStepType.quiz,
        questions: [
          QuizQuestion(
            question: quizQuestion,
            options: quizOptions,
            correctIndex: correctIdx,
            explanation: explanation,
          ),
        ],
        isLoaded: true,
      ),
      LessonStep(
        id: '${lesson.id}_chat',
        title: 'Reflect & Discuss',
        type: LessonStepType.chat,
        chatPrompt: chatData['prompt'] as String? ??
            'How do the ideas in this lesson connect to your own experience?',
        isLoaded: true,
      ),
    ];

    return lesson.copyWith(steps: steps);
  }

  // ─── Fallback curriculum (no AI key) ─────────────────────────────────────

  Curriculum _fallbackCurriculum(String topic, String userId) {
    final topicLower = topic.toLowerCase();

    // Match common topics
    if (topicLower.contains('philos')) {
      return _philosophyCurriculum(topic, userId);
    } else if (topicLower.contains('ai') ||
        topicLower.contains('machine learning') ||
        topicLower.contains('engineering')) {
      return _aiCurriculum(topic, userId);
    } else if (topicLower.contains('book') ||
        topicLower.contains('classic') ||
        topicLower.contains('literature')) {
      return _classicsCurriculum(topic, userId);
    } else if (topicLower.contains('psych')) {
      return _psychologyCurriculum(topic, userId);
    } else {
      return _genericCurriculum(topic, userId);
    }
  }

  Curriculum _philosophyCurriculum(String topic, String userId) {
    return _initializeLocks(Curriculum(
      id: const Uuid().v4(),
      userId: userId,
      topic: topic,
      title: 'Philosophy Mastery',
      description:
          'Explore the greatest philosophical works from ancient wisdom to modern thought.',
      createdAt: DateTime.now(),
      levels: [
        CurriculumLevel(
          number: 1,
          title: 'Ancient Wisdom',
          description: 'The foundations of Western thought',
          bookTitle: "Plato's Republic",
          bookAuthor: 'Plato',
          colorHex: '#58CC02',
          iconEmoji: '🏛️',
          lessons: _buildLessons(1, [
            "The Allegory of the Cave",
            "Justice & The Soul",
            "The Philosopher King",
          ]),
        ),
        CurriculumLevel(
          number: 2,
          title: 'Stoic Resilience',
          description: 'Practical wisdom for a good life',
          bookTitle: 'Meditations',
          bookAuthor: 'Marcus Aurelius',
          colorHex: '#1CB0F6',
          iconEmoji: '🌿',
          lessons: _buildLessons(2, [
            "Control What You Can",
            "The Present Moment",
            "Virtue as the Highest Good",
          ]),
        ),
        CurriculumLevel(
          number: 3,
          title: 'Existential Questions',
          description: 'Finding meaning and freedom',
          bookTitle: 'Being and Nothingness',
          bookAuthor: 'Jean-Paul Sartre',
          colorHex: '#CE82FF',
          iconEmoji: '🔍',
          lessons: _buildLessons(3, [
            "Existence Precedes Essence",
            "Radical Freedom",
            "Bad Faith & Authenticity",
          ]),
        ),
        CurriculumLevel(
          number: 4,
          title: 'Modern Ethics',
          description: 'How to think about right and wrong',
          bookTitle: 'Justice: What\'s the Right Thing to Do?',
          bookAuthor: 'Michael Sandel',
          colorHex: '#FF9600',
          iconEmoji: '⚖️',
          lessons: _buildLessons(4, [
            "Utilitarianism in Practice",
            "Kant's Moral Law",
            "Community & Common Good",
          ]),
        ),
      ],
    ));
  }

  Curriculum _aiCurriculum(String topic, String userId) {
    return _initializeLocks(Curriculum(
      id: const Uuid().v4(),
      userId: userId,
      topic: topic,
      title: 'AI & Machine Learning',
      description:
          'Master artificial intelligence from fundamentals to cutting-edge research.',
      createdAt: DateTime.now(),
      levels: [
        CurriculumLevel(
          number: 1,
          title: 'AI Fundamentals',
          description: 'Understanding the big picture',
          bookTitle: 'Artificial Intelligence: A Modern Approach',
          bookAuthor: 'Russell & Norvig',
          colorHex: '#58CC02',
          iconEmoji: '🤖',
          lessons: _buildLessons(1, [
            "What is Intelligence?",
            "Search & Problem Solving",
            "Knowledge Representation",
          ]),
        ),
        CurriculumLevel(
          number: 2,
          title: 'Machine Learning',
          description: 'Teaching machines to learn',
          bookTitle: 'The Hundred-Page Machine Learning Book',
          bookAuthor: 'Andriy Burkov',
          colorHex: '#1CB0F6',
          iconEmoji: '📊',
          lessons: _buildLessons(2, [
            "Supervised Learning",
            "Neural Networks Basics",
            "Model Evaluation",
          ]),
        ),
        CurriculumLevel(
          number: 3,
          title: 'Deep Learning',
          description: 'The engines behind modern AI',
          bookTitle: 'Deep Learning',
          bookAuthor: 'Goodfellow, Bengio & Courville',
          colorHex: '#CE82FF',
          iconEmoji: '🧠',
          lessons: _buildLessons(3, [
            "Backpropagation Explained",
            "Convolutional Networks",
            "Attention & Transformers",
          ]),
        ),
        CurriculumLevel(
          number: 4,
          title: 'AI Ethics & Future',
          description: 'The societal implications of AI',
          bookTitle: 'Human Compatible',
          bookAuthor: 'Stuart Russell',
          colorHex: '#FF9600',
          iconEmoji: '🌍',
          lessons: _buildLessons(4, [
            "The Alignment Problem",
            "AI Safety Approaches",
            "Building Beneficial AI",
          ]),
        ),
      ],
    ));
  }

  Curriculum _classicsCurriculum(String topic, String userId) {
    return _initializeLocks(Curriculum(
      id: const Uuid().v4(),
      userId: userId,
      topic: topic,
      title: '100 Must-Read Books',
      description:
          'Journey through the most influential books in human history.',
      createdAt: DateTime.now(),
      levels: [
        CurriculumLevel(
          number: 1,
          title: 'Timeless Classics',
          description: 'Books that shaped civilization',
          bookTitle: 'Crime and Punishment',
          bookAuthor: 'Fyodor Dostoevsky',
          colorHex: '#58CC02',
          iconEmoji: '📚',
          lessons: _buildLessons(1, [
            "Raskolnikov's Theory",
            "Guilt & Conscience",
            "Redemption & Love",
          ]),
        ),
        CurriculumLevel(
          number: 2,
          title: 'Dystopian Visions',
          description: 'Warnings from literature',
          bookTitle: '1984',
          bookAuthor: 'George Orwell',
          colorHex: '#1CB0F6',
          iconEmoji: '👁️',
          lessons: _buildLessons(2, [
            "Big Brother & Surveillance",
            "Doublethink & Language",
            "Resistance & Submission",
          ]),
        ),
        CurriculumLevel(
          number: 3,
          title: 'Human Condition',
          description: 'Literature about what it means to be human',
          bookTitle: 'To Kill a Mockingbird',
          bookAuthor: 'Harper Lee',
          colorHex: '#CE82FF',
          iconEmoji: '🦜',
          lessons: _buildLessons(3, [
            "Innocence & Prejudice",
            "Moral Courage",
            "Justice & Empathy",
          ]),
        ),
        CurriculumLevel(
          number: 4,
          title: 'Modern Masterworks',
          description: '20th century literature',
          bookTitle: 'One Hundred Years of Solitude',
          bookAuthor: 'Gabriel García Márquez',
          colorHex: '#FF9600',
          iconEmoji: '🌺',
          lessons: _buildLessons(4, [
            "Magical Realism",
            "The Buendía Family Curse",
            "Time, Memory & Solitude",
          ]),
        ),
      ],
    ));
  }

  Curriculum _psychologyCurriculum(String topic, String userId) {
    return _initializeLocks(Curriculum(
      id: const Uuid().v4(),
      userId: userId,
      topic: topic,
      title: 'Understanding the Mind',
      description:
          'Explore human psychology from behavior to consciousness.',
      createdAt: DateTime.now(),
      levels: [
        CurriculumLevel(
          number: 1,
          title: 'Behavioral Foundations',
          description: 'Why we do what we do',
          bookTitle: 'Thinking, Fast and Slow',
          bookAuthor: 'Daniel Kahneman',
          colorHex: '#58CC02',
          iconEmoji: '💭',
          lessons: _buildLessons(1, [
            "System 1 vs System 2",
            "Cognitive Biases",
            "Decision Making",
          ]),
        ),
        CurriculumLevel(
          number: 2,
          title: 'Social Psychology',
          description: 'How others shape our minds',
          bookTitle: 'Influence',
          bookAuthor: 'Robert Cialdini',
          colorHex: '#1CB0F6',
          iconEmoji: '👥',
          lessons: _buildLessons(2, [
            "Reciprocity & Commitment",
            "Social Proof",
            "Authority & Scarcity",
          ]),
        ),
        CurriculumLevel(
          number: 3,
          title: 'Motivation & Flow',
          description: 'The science of peak performance',
          bookTitle: 'Flow',
          bookAuthor: 'Mihaly Csikszentmihalyi',
          colorHex: '#CE82FF',
          iconEmoji: '🌊',
          lessons: _buildLessons(3, [
            "What is Flow State?",
            "Conditions for Flow",
            "Flow in Daily Life",
          ]),
        ),
        CurriculumLevel(
          number: 4,
          title: 'Growth Mindset',
          description: 'The psychology of achievement',
          bookTitle: 'Mindset: The New Psychology of Success',
          bookAuthor: 'Carol Dweck',
          colorHex: '#FF9600',
          iconEmoji: '🌱',
          lessons: _buildLessons(4, [
            "Fixed vs Growth Mindset",
            "Power of Yet",
            "Praising Effort Not Talent",
          ]),
        ),
      ],
    ));
  }

  Curriculum _genericCurriculum(String topic, String userId) {
    return _initializeLocks(Curriculum(
      id: const Uuid().v4(),
      userId: userId,
      topic: topic,
      title: '${_capitalize(topic)} Mastery',
      description:
          'A curated learning journey through the best books on $topic.',
      createdAt: DateTime.now(),
      levels: [
        CurriculumLevel(
          number: 1,
          title: 'Fundamentals',
          description: 'Core concepts and principles',
          bookTitle: 'The Essential Guide to $topic',
          bookAuthor: 'Expert Author',
          colorHex: '#58CC02',
          iconEmoji: '🌱',
          lessons: _buildLessons(1, [
            "Core Principles",
            "Historical Context",
            "Key Concepts",
          ]),
        ),
        CurriculumLevel(
          number: 2,
          title: 'Intermediate',
          description: 'Deeper understanding',
          bookTitle: '$topic: Advanced Perspectives',
          bookAuthor: 'Expert Author',
          colorHex: '#1CB0F6',
          iconEmoji: '🔬',
          lessons: _buildLessons(2, [
            "Advanced Theory",
            "Practical Applications",
            "Case Studies",
          ]),
        ),
        CurriculumLevel(
          number: 3,
          title: 'Advanced',
          description: 'Expert-level mastery',
          bookTitle: 'Mastering $topic',
          bookAuthor: 'Expert Author',
          colorHex: '#CE82FF',
          iconEmoji: '🎓',
          lessons: _buildLessons(3, [
            "Expert Insights",
            "Cutting-Edge Research",
            "Future Directions",
          ]),
        ),
      ],
    ));
  }

  // ─── Fallback lesson content ──────────────────────────────────────────────

  Lesson _fallbackLessonContent(
      Lesson lesson, CurriculumLevel level, String topic) {
    final content = '''
${lesson.title}

This lesson explores "${lesson.title}" from "${level.bookTitle}" by ${level.bookAuthor}.

Understanding ${lesson.title} is central to mastering $topic. The author presents a framework that has influenced generations of thinkers and practitioners in this field.

The core argument begins with a fundamental observation: our assumptions about ${lesson.title.toLowerCase()} often lead us astray. By carefully examining these assumptions, we can develop a clearer, more nuanced understanding.

Key insight #1: The subject cannot be understood in isolation. Context matters enormously — historical, cultural, and personal contexts all shape how we interpret the ideas presented here.

Key insight #2: Theory must connect to practice. The most enduring ideas from this book are those that can be applied in everyday situations. Look for opportunities to test these concepts in your own life.

Key insight #3: Progress requires patience. Mastering these ideas doesn't happen overnight. The author emphasizes the importance of returning to core principles repeatedly, each time discovering new layers of meaning.

As you reflect on this lesson, consider how these ideas challenge your existing beliefs. The best learning happens at the edge of comfort — where familiar ideas meet new perspectives.

The next step is to test your understanding with a short quiz, then discuss your thoughts with our AI companion. Together, these activities will help cement the concepts in your long-term memory.

Remember: the goal isn't just to know these ideas, but to let them change how you think and act in the world.
''';

    final steps = [
      LessonStep(
        id: '${lesson.id}_read',
        title: 'Reading: ${lesson.title}',
        type: LessonStepType.read,
        content: content,
        isLoaded: true,
      ),
      LessonStep(
        id: '${lesson.id}_quiz',
        title: 'Knowledge Check',
        type: LessonStepType.quiz,
        questions: [
          QuizQuestion(
            question:
                'What is the central theme of "${lesson.title}" in ${level.bookTitle}?',
            options: [
              'Understanding context and challenging assumptions',
              'Memorizing historical dates',
              'Following strict rules without question',
              'Avoiding difficult topics',
            ],
            correctIndex: 0,
            explanation:
                'The lesson emphasizes understanding context and challenging our assumptions to gain deeper insight.',
          ),
          QuizQuestion(
            question:
                'According to ${level.bookAuthor}, how should theory relate to practice?',
            options: [
              'Theory is more important than practice',
              'They should remain separate domains',
              'Theory must connect to and inform practice',
              'Practice makes theory irrelevant',
            ],
            correctIndex: 2,
            explanation:
                'The author argues that the most valuable ideas are those that can be applied in real situations.',
          ),
          QuizQuestion(
            question: 'What does the author say about mastering these ideas?',
            options: [
              'It happens quickly with the right techniques',
              'It requires patience and repeated return to core principles',
              'Only experts can truly master them',
              'Mastery is impossible',
            ],
            correctIndex: 1,
            explanation:
                'Mastery requires patience — returning to core principles repeatedly reveals new layers of meaning.',
          ),
        ],
        isLoaded: true,
      ),
      LessonStep(
        id: '${lesson.id}_chat',
        title: 'Reflect & Discuss',
        type: LessonStepType.chat,
        chatPrompt:
            'You just read about "${lesson.title}" from ${level.bookTitle}. '
            'How do these ideas connect to your own life or work? '
            'Can you think of a specific situation where applying these concepts might have made a difference?',
        isLoaded: true,
      ),
    ];

    return lesson.copyWith(steps: steps);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<Lesson> _buildLessons(int levelNum, List<String> titles) {
    return titles.asMap().entries.map((e) {
      final num = e.key + 1;
      return Lesson(
        id: 'l${levelNum}_${num}',
        title: e.value,
        number: num,
        steps: [],
        isUnlocked: levelNum == 1 && num == 1,
      );
    }).toList();
  }

  /// Set unlock state: Level 1 unlocked, Lesson 1 of each level accessible.
  Curriculum _initializeLocks(Curriculum c) {
    final levels = c.levels.asMap().entries.map((levelEntry) {
      final levelIdx = levelEntry.key;
      final level = levelEntry.value;
      final levelUnlocked = levelIdx == 0;
      final lessons = level.lessons.asMap().entries.map((lessonEntry) {
        final lessonIdx = lessonEntry.key;
        final lesson = lessonEntry.value;
        // First lesson of first level is always unlocked
        final lessonUnlocked = levelUnlocked && lessonIdx == 0;
        return lesson.copyWith(isUnlocked: lessonUnlocked);
      }).toList();
      return level.copyWith(lessons: lessons, isUnlocked: levelUnlocked);
    }).toList();
    return c.copyWith(levels: levels);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
