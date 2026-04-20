import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/curriculum.dart';
import '../../providers/curriculum_provider.dart';
import '../../providers/auth_provider.dart';
import 'lesson_screen.dart';
import 'topic_input_screen.dart';

class CurriculumMapScreen extends ConsumerWidget {
  const CurriculumMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currAsync = ref.watch(curriculumProvider);

    return currAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (curriculum) {
        if (curriculum == null) {
          return const TopicInputScreen();
        }
        return _CurriculumMapView(curriculum: curriculum);
      },
    );
  }
}

class _CurriculumMapView extends ConsumerWidget {
  final Curriculum curriculum;

  const _CurriculumMapView({required this.curriculum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref, user?.displayName ?? 'Learner'),
          SliverToBoxAdapter(
            child: _buildStatsBar(context),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _LevelSection(
                  level: curriculum.levels[index],
                  levelIndex: index,
                );
              },
              childCount: curriculum.levels.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, WidgetRef ref, String displayName) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            curriculum.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Hey, $displayName! 👋',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // XP chip
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.xpGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${curriculum.totalXP} XP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.xpGoldDark,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: AppColors.textSecondary),
          tooltip: 'New topic',
          onPressed: () => _confirmReset(context, ref),
        ),
      ],
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final completed = curriculum.completedLessons;
    final total = curriculum.totalLessons;
    final progress = curriculum.overallProgress;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$completed / $total lessons complete',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start New Topic?'),
        content: const Text(
          'Your current progress will be lost. This will let you choose a new topic to learn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Reset emits AsyncData(null) → CurriculumMapScreen rebuilds
              // and shows TopicInputScreen automatically
              await ref
                  .read(curriculumProvider.notifier)
                  .resetCurriculum();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ─── Level Section ────────────────────────────────────────────────────────────

class _LevelSection extends ConsumerWidget {
  final CurriculumLevel level;
  final int levelIndex;

  const _LevelSection({
    required this.level,
    required this.levelIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildLevelHeader(context),
        const SizedBox(height: 16),
        _buildLessonPath(context, ref),
      ],
    );
  }

  Widget _buildLevelHeader(BuildContext context) {
    final color = level.color;
    final isLocked = !level.isUnlocked;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.inputBg
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked ? AppColors.border : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isLocked ? AppColors.locked : color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                isLocked ? '🔒' : level.iconEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Level ${level.number}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLocked ? AppColors.lockedDark : color,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isLocked && level.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMPLETE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  level.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isLocked
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${level.bookTitle} · ${level.bookAuthor}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLocked
                        ? AppColors.textHint
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isLocked) ...[
            Column(
              children: [
                Text(
                  '${level.completedLessons}/${level.lessons.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: level.progressPercent,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonPath(BuildContext context, WidgetRef ref) {
    // Zigzag path: odd bubbles lean left, even lean right
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: List.generate(level.lessons.length, (i) {
          final lesson = level.lessons[i];
          final isLeft = i.isEven;

          return Padding(
            padding: EdgeInsets.only(
              left: isLeft ? 40 : 120,
              right: isLeft ? 120 : 40,
              bottom: 4,
            ),
            child: Column(
              children: [
                if (i > 0)
                  Padding(
                    padding: EdgeInsets.only(
                      left: isLeft ? 30 : 0,
                      right: isLeft ? 0 : 30,
                    ),
                    child: _buildConnector(
                      color: level.color,
                      isLocked: !level.isUnlocked,
                    ),
                  ),
                _LessonBubble(
                  lesson: lesson,
                  level: level,
                  levelIndex: levelIndex,
                  lessonIndex: i,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConnector({required Color color, required bool isLocked}) {
    return SizedBox(
      height: 24,
      child: CustomPaint(
        size: const Size(double.infinity, 24),
        painter: _ConnectorPainter(
          color: isLocked ? AppColors.border : color.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Color color;
  _ConnectorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dashed vertical line
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    final x = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, math.min(startY + dashHeight, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) => old.color != color;
}

// ─── Lesson Bubble ────────────────────────────────────────────────────────────

class _LessonBubble extends ConsumerWidget {
  final Lesson lesson;
  final CurriculumLevel level;
  final int levelIndex;
  final int lessonIndex;

  const _LessonBubble({
    required this.lesson,
    required this.level,
    required this.levelIndex,
    required this.lessonIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = !lesson.isUnlocked;
    final isCompleted = lesson.isCompleted;
    final color = level.color;

    return GestureDetector(
      onTap: isLocked ? () => _showLockedToast(context) : () => _openLesson(context, ref),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked
                  ? AppColors.inputBg
                  : isCompleted
                      ? color
                      : AppColors.surface,
              border: Border.all(
                color: isLocked
                    ? AppColors.border
                    : isCompleted
                        ? color
                        : color,
                width: isCompleted ? 0 : 3,
              ),
              boxShadow: isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock_rounded,
                      color: AppColors.lockedDark, size: 28)
                  : isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 32)
                      : Text(
                          '${lessonIndex + 1}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: Text(
              lesson.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLocked
                    ? AppColors.textHint
                    : AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          if (!isLocked && !isCompleted && lesson.steps.isNotEmpty) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: lesson.progressPercent,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLockedToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete previous lessons to unlock this one!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openLesson(BuildContext context, WidgetRef ref) async {
    // Load lesson content first (lazy)
    if (lesson.steps.isEmpty) {
      // Show brief loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading lesson...'),
                ],
              ),
            ),
          ),
        ),
      );

      await ref
          .read(curriculumProvider.notifier)
          .loadLessonContent(levelIndex, lessonIndex);

      if (context.mounted) Navigator.pop(context);
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonScreen(
            levelIndex: levelIndex,
            lessonIndex: lessonIndex,
          ),
        ),
      );
    }
  }
}
