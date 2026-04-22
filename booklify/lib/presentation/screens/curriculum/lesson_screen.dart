import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/curriculum.dart';
import '../../providers/curriculum_provider.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final int levelIndex;
  final int lessonIndex;

  const LessonScreen({
    super.key,
    required this.levelIndex,
    required this.lessonIndex,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with SingleTickerProviderStateMixin {
  int _stepIndex = 0;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation =
        Tween<double>(begin: 0, end: 0).animate(_progressController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncStep();
      _loadContentIfNeeded(); // fetch quiz/chat content if missing
    });
  }

  // Trigger AI content loading whenever any step in this lesson is unloaded.
  Future<void> _loadContentIfNeeded() async {
    final curr = ref.read(curriculumProvider).value;
    if (curr == null) return;
    if (widget.levelIndex >= curr.levels.length) return;
    final level = curr.levels[widget.levelIndex];
    if (widget.lessonIndex >= level.lessons.length) return;
    final lesson = level.lessons[widget.lessonIndex];
    if (lesson.steps.any((s) => !s.isLoaded)) {
      await ref.read(curriculumProvider.notifier).loadLessonContent(
            widget.levelIndex,
            widget.lessonIndex,
          );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _syncStep() {
    final curr = ref.read(curriculumProvider).value;
    if (curr == null) return;
    final lesson =
        curr.levels[widget.levelIndex].lessons[widget.lessonIndex];
    for (int i = 0; i < lesson.steps.length; i++) {
      if (!lesson.steps[i].isCompleted) {
        setState(() => _stepIndex = i);
        return;
      }
    }
  }

  Lesson? _lesson(WidgetRef ref) {
    final curr = ref.watch(curriculumProvider).value;
    if (curr == null) return null;
    return curr.levels[widget.levelIndex].lessons[widget.lessonIndex];
  }

  CurriculumLevel? _level(WidgetRef ref) {
    final curr = ref.watch(curriculumProvider).value;
    if (curr == null) return null;
    return curr.levels[widget.levelIndex];
  }

  void _animateProgress(int stepCount) {
    final newProgress =
        stepCount == 0 ? 0.0 : (_stepIndex + 1) / stepCount;
    _progressAnimation =
        Tween<double>(begin: _prevProgress, end: newProgress)
            .animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
    _prevProgress = newProgress;
    _progressController
      ..reset()
      ..forward();
  }

  Future<void> _completeStep() async {
    await ref.read(curriculumProvider.notifier).completeStep(
          widget.levelIndex,
          widget.lessonIndex,
          _stepIndex,
        );

    final lesson = _lesson(ref);
    if (lesson == null) return;

    _animateProgress(lesson.steps.length);

    if (_stepIndex < lesson.steps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      // All steps done — show reward dialog
      _showCompletionDialog(lesson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson(ref);
    final level = _level(ref);

    if (lesson == null || level == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final color = level.color;
    final step = _stepIndex < lesson.steps.length
        ? lesson.steps[_stepIndex]
        : null;
    final stepCount = lesson.steps.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, lesson, level, color, stepCount),
            Expanded(
              child: step == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStepContent(step, lesson, color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Lesson lesson,
    CurriculumLevel level,
    Color color,
    int stepCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // XP reward badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '+${lesson.xpReward}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.xpGoldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(stepCount, (i) {
                final isDone = i < _stepIndex ||
                    (lesson.steps.isNotEmpty &&
                        lesson.steps[i].isCompleted);
                final isCurrent = i == _stepIndex;
                return Expanded(
                  child: Container(
                    height: 28,
                    margin: EdgeInsets.only(right: i < stepCount - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isDone
                          ? color
                          : isCurrent
                              ? color.withOpacity(0.2)
                              : AppColors.inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: i < lesson.steps.length
                          ? Icon(
                              lesson.steps[i].icon,
                              size: 14,
                              color: isDone
                                  ? Colors.white
                                  : isCurrent
                                      ? color
                                      : AppColors.lockedDark,
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStepContent(
      LessonStep step, Lesson lesson, Color color) {
    switch (step.type) {
      case LessonStepType.read:
        return _ReadStep(
          step: step,
          color: color,
          onComplete: _completeStep,
        );
      case LessonStepType.quiz:
        return _QuizStep(
          step: step,
          color: color,
          onComplete: _completeStep,
        );
      case LessonStepType.chat:
        return _ChatStep(
          step: step,
          color: color,
          onComplete: _completeStep,
        );
    }
  }

  void _showCompletionDialog(Lesson lesson) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LessonCompleteDialog(
        lesson: lesson,
        onContinue: () {
          Navigator.pop(ctx);
          Navigator.pop(context); // Back to map
        },
      ),
    );
  }
}

// ─── Read Step ────────────────────────────────────────────────────────────────
// Clean reading experience — no redirects, no external buttons.
// Content is the actual book passage split by the provider.

class _ReadStep extends StatefulWidget {
  final LessonStep step;
  final Color color;
  final VoidCallback onComplete;

  const _ReadStep({
    required this.step,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_ReadStep> createState() => _ReadStepState();
}

class _ReadStepState extends State<_ReadStep> {
  late PageController _pageController;
  int _currentPage = 0;
  List<String> _pages = [''];
  BoxConstraints? _lastConstraints;

  static const _textStyle = TextStyle(
    fontSize: 17,
    height: 1.8,
    color: AppColors.textPrimary,
    fontFamily: 'Georgia',
    letterSpacing: 0.1,
  );

  // Approx height of the READ + title header on page 0 (icon row + gap + title + gap)
  static const double _firstPageHeaderHeight = 120.0;
  // Padding top + bottom inside each page
  static const double _verticalPadding = 40.0;
  // Horizontal padding each side
  static const double _horizontalPadding = 40.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Re-paginate whenever the available area changes.
  void _maybeRepaginate(BoxConstraints constraints) {
    if (constraints == _lastConstraints) return;
    _lastConstraints = constraints;

    // Subtract padding on both sides and a small safety margin (8px)
    final textWidth = constraints.maxWidth - _horizontalPadding;
    final pageHeight = constraints.maxHeight - _verticalPadding - 8;

    final newPages = _paginateForSize(
      widget.step.content,
      textWidth,
      pageHeight,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _pages = newPages;
        if (_currentPage >= _pages.length) _currentPage = 0;
      });
    });
  }

  /// Paginate `text` so each page fits within `maxHeight` pixels at `maxWidth`.
  List<String> _paginateForSize(
      String text, double maxWidth, double maxHeight) {
    if (text.trim().isEmpty) return ['No content available for this section.'];

    // Split into atomic chunks: first by paragraph, then split any paragraph
    // that is longer than one page by sentence.
    final rawParas = text
        .split(RegExp(r'\n\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (rawParas.isEmpty) return [text];

    // Break a paragraph into sentence-sized pieces when it alone overflows.
    List<String> chunks = [];
    for (final para in rawParas) {
      final alone = TextPainter(
        text: TextSpan(text: para, style: _textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      if (alone.height <= maxHeight) {
        chunks.add(para);
      } else {
        // Split by sentence boundary and re-group
        final sentences =
            para.split(RegExp(r'(?<=[.!?])\s+'));
        final sentBuf = StringBuffer();
        for (final s in sentences) {
          final candidate =
              sentBuf.isEmpty ? s : '${sentBuf.toString()} $s';
          final p = TextPainter(
            text: TextSpan(text: candidate, style: _textStyle),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: maxWidth);
          if (p.height > maxHeight && sentBuf.isNotEmpty) {
            chunks.add(sentBuf.toString().trim());
            sentBuf.clear();
            sentBuf.write(s);
          } else {
            if (sentBuf.isNotEmpty) sentBuf.write(' ');
            sentBuf.write(s);
          }
        }
        if (sentBuf.isNotEmpty) chunks.add(sentBuf.toString().trim());
      }
    }

    final pages = <String>[];
    final buf = StringBuffer();
    bool isFirstPage = true;

    for (final chunk in chunks) {
      final candidate =
          buf.isEmpty ? chunk : '${buf.toString()}\n\n$chunk';

      // First page reserves space for the READ + title header
      final availableH =
          maxHeight - (isFirstPage ? _firstPageHeaderHeight : 0.0);

      final painter = TextPainter(
        text: TextSpan(text: candidate, style: _textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (painter.height > availableH && buf.isNotEmpty) {
        pages.add(buf.toString().trim());
        buf.clear();
        isFirstPage = false;
        buf.write(chunk);
      } else {
        if (buf.isNotEmpty) buf.write('\n\n');
        buf.write(chunk);
      }
    }
    if (buf.isNotEmpty) pages.add(buf.toString().trim());
    return pages.isEmpty ? [text] : pages;
  }

  bool get _onLastPage => _currentPage >= _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    final totalPages = _pages.length;

    return Column(
      children: [
        Expanded(
          // LayoutBuilder lives inside Expanded so constraints.maxHeight
          // is exactly the reading area height, not the full screen.
          child: LayoutBuilder(builder: (context, constraints) {
            _maybeRepaginate(constraints);
            return PageView.builder(
              controller: _pageController,
              onPageChanged: (p) => setState(() => _currentPage = p),
              itemCount: totalPages,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // READ label + title on first page only
                      if (index == 0) ...[
                        Row(
                          children: [
                            Icon(widget.step.icon,
                                color: widget.color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'READ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: widget.color,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.step.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(height: 1.25),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        _pages[index],
                        style: _textStyle,
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
        // Bottom bar: page nav on mid-pages, Continue on last page
        if (_onLastPage)
          _BottomContinueBar(
            color: widget.color,
            enabled: true,
            label: 'Continue',
            onPressed: widget.onComplete,
          )
        else
          _PageNavBar(
            current: _currentPage,
            total: totalPages,
            color: widget.color,
            onNext: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
      ],
    );
  }
}

// ─── Quiz Step ────────────────────────────────────────────────────────────────

class _QuizStep extends StatefulWidget {
  final LessonStep step;
  final Color color;
  final VoidCallback onComplete;

  const _QuizStep({
    required this.step,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<_QuizStep> {
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;

  bool get _hasQuestions => widget.step.questions.isNotEmpty;
  QuizQuestion get _question => widget.step.questions[_currentQuestion];
  bool get _isLastQuestion =>
      _currentQuestion == widget.step.questions.length - 1;

  void _selectAnswer(int index) {
    if (_answered) return;
    final correct = index == _question.correctIndex;
    if (correct) _correctCount++;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      widget.onComplete();
    } else {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Questions haven't loaded yet — show a spinner while AI generates them
    if (!_hasQuestions) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: widget.color, strokeWidth: 2),
                    const SizedBox(height: 20),
                    Text(
                      'Generating quiz questions…',
                      style: TextStyle(color: widget.color, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The AI is crafting questions based on this chapter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Allow skipping if AI is unavailable
          _BottomContinueBar(
            color: widget.color,
            enabled: true,
            label: 'Skip for Now',
            onPressed: widget.onComplete,
          ),
        ],
      );
    }

    final q = _question;
    final questionCount = widget.step.questions.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.step.icon,
                        color: widget.color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'QUESTION ${_currentQuestion + 1} OF $questionCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.color,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  q.question,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                ...List.generate(q.options.length, (i) {
                  return _AnswerOption(
                    text: q.options[i],
                    index: i,
                    selected: _selectedAnswer == i,
                    answered: _answered,
                    isCorrect: i == q.correctIndex,
                    onTap: () => _selectAnswer(i),
                    color: widget.color,
                  );
                }),
                if (_answered && q.explanation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedAnswer == q.correctIndex
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAnswer == q.correctIndex
                              ? '✅'
                              : '❌',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.explanation,
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedAnswer == q.correctIndex
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        _BottomContinueBar(
          color: widget.color,
          enabled: _answered,
          label: _isLastQuestion ? 'Finish Quiz' : 'Next Question',
          onPressed: _nextQuestion,
        ),
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String text;
  final int index;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final VoidCallback onTap;
  final Color color;

  const _AnswerOption({
    required this.text,
    required this.index,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.textPrimary;

    if (answered) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
      } else if (selected) {
        borderColor = AppColors.error;
        bgColor = AppColors.errorLight;
        textColor = AppColors.error;
      }
    } else if (selected) {
      borderColor = color;
      bgColor = color.withOpacity(0.1);
      textColor = color;
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: answered && isCorrect
                    ? AppColors.success
                    : answered && selected
                        ? AppColors.error
                        : selected
                            ? color
                            : AppColors.inputBg,
              ),
              child: Center(
                child: Text(
                  answered
                      ? (isCorrect ? '✓' : selected ? '✗' : '')
                      : String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: answered
                        ? Colors.white
                        : selected
                            ? Colors.white
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Step ────────────────────────────────────────────────────────────────

class _ChatStep extends StatefulWidget {
  final LessonStep step;
  final Color color;
  final VoidCallback onComplete;

  const _ChatStep({
    required this.step,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_ChatStep> createState() => _ChatStepState();
}

class _ChatStepState extends State<_ChatStep> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[];
  bool _isTyping = false;
  bool _hasReplied = false;

  @override
  void initState() {
    super.initState();
    // Initial AI prompt
    _messages.add(_ChatMessage(
      text: widget.step.chatPrompt,
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });

    // Simulate AI thinking
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _hasReplied = true;
          _messages.add(_ChatMessage(
            text: _getAIResponse(text),
            isUser: false,
          ));
        });
      }
    });
  }

  String _getAIResponse(String userMessage) {
    // Simple contextual responses
    final lower = userMessage.toLowerCase();
    if (lower.contains('not sure') || lower.contains("don't know")) {
      return "That's completely fine! Uncertainty is a great starting point. Let me guide you: the key idea here is that knowledge grows through questioning. What's one small aspect you feel you *do* understand?";
    } else if (lower.length < 30) {
      return "Interesting! Can you expand on that thought? I'd love to hear more about what specifically resonates with you or challenges your thinking.";
    } else {
      return "That's a thoughtful reflection! 🌟 You've touched on something important. The connection you're making between these ideas and your own experience is exactly the kind of deep learning that sticks. Are there other areas of your life where you see similar patterns?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(widget.step.icon, color: widget.color, size: 18),
              const SizedBox(width: 6),
              Text(
                'REFLECT & DISCUSS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (_isTyping && i == _messages.length) {
                return const _TypingIndicator();
              }
              return _MessageBubble(
                message: _messages[i],
                color: widget.color,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts…',
                    filled: true,
                    fillColor: AppColors.inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        if (_hasReplied)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _BottomContinueBar(
              color: widget.color,
              enabled: true,
              label: 'Complete Lesson',
              onPressed: widget.onComplete,
            ),
          ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final Color color;

  const _MessageBubble({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? color : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            const SizedBox(width: 4),
            _Dot(delay: 200),
            const SizedBox(width: 4),
            _Dot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.textHint,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

/// Shown between pages of a read step — page counter + Next arrow button.
class _PageNavBar extends StatelessWidget {
  final int current;
  final int total;
  final Color color;
  final VoidCallback onNext;

  const _PageNavBar({
    required this.current,
    required this.total,
    required this.color,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Page counter text
            Text(
              '${current + 1} / $total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            // Next page button
            GestureDetector(
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomContinueBar extends StatelessWidget {
  final Color color;
  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  const _BottomContinueBar({
    required this.color,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? color : AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lesson Complete Dialog ───────────────────────────────────────────────────

class _LessonCompleteDialog extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onContinue;

  const _LessonCompleteDialog({
    required this.lesson,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'Lesson Complete!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              lesson.title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.xpGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        '+${lesson.xpReward} XP',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.xpGoldDark,
                        ),
                      ),
                      const Text(
                        'earned',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
