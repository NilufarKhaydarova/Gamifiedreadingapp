import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/curriculum_provider.dart';
import '../curriculum/topic_input_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final currAsync = ref.watch(curriculumProvider);

    final displayName = user?.displayName ?? 'Learner';
    final initial = displayName.isEmpty ? 'L' : displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref, displayName, initial),
          SliverToBoxAdapter(
            child: currAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (curriculum) => _buildBody(context, ref, curriculum),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref,
      String displayName, String initial) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.forestDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Forest background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A2E1A),
                    Color(0xFF1A472A),
                    Color(0xFF2D6A4F),
                  ],
                ),
              ),
            ),
            // Stars
            const _StarField(),
            // Trees at bottom
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ForestSilhouette(),
            ),
            // Avatar + name
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          onPressed: () => _confirmSignOut(context, ref),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, curriculum) {
    final xp = curriculum?.totalXP ?? 0;
    final streak = curriculum?.streak ?? 0;
    final completedLessons = curriculum?.completedLessons ?? 0;
    final totalLessons = curriculum?.totalLessons ?? 0;
    final topic = curriculum?.topic ?? '';
    final title = curriculum?.title ?? '';
    final level = _xpToLevel(xp);
    final xpInLevel = xp % 500;
    final xpForNext = 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // XP Level card
        _buildXPCard(context, xp, level, xpInLevel, xpForNext),
        const SizedBox(height: 16),
        // Stats row
        _buildStatsRow(context, streak, completedLessons, totalLessons),
        const SizedBox(height: 20),
        // Forest / Tree visualization
        _buildForestCard(context, completedLessons, totalLessons),
        const SizedBox(height: 20),
        // Streak calendar
        _buildStreakCalendar(context, streak),
        const SizedBox(height: 20),
        // Current curriculum
        if (curriculum != null) ...[
          _buildCurriculumCard(context, ref, title, topic, completedLessons, totalLessons),
          const SizedBox(height: 20),
        ],
        // Sign out
        _buildDangerZone(context, ref),
      ],
    );
  }

  Widget _buildXPCard(BuildContext context, int xp, int level,
      int xpInLevel, int xpForNext) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A472A), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestDark.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.xpGold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '$xp total XP',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$xpInLevel / $xpForNext XP',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'to Level ${level + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.xpGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: xpInLevel / xpForNext,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.xpGold),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int streak,
      int completedLessons, int totalLessons) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            emoji: '🔥',
            value: '$streak',
            label: 'Day Streak',
            color: AppColors.streakOrange,
          ),
          const SizedBox(width: 10),
          _StatCard(
            emoji: '📚',
            value: '$completedLessons',
            label: 'Lessons Done',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            emoji: '🎯',
            value: totalLessons > 0
                ? '${(completedLessons / totalLessons * 100).round()}%'
                : '0%',
            label: 'Progress',
            color: AppColors.gems,
          ),
        ],
      ),
    );
  }

  Widget _buildForestCard(
      BuildContext context, int completedLessons, int totalLessons) {
    final progress = totalLessons > 0
        ? completedLessons / totalLessons
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌲', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Your Learning Forest',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _forestDescription(completedLessons),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: _ForestVisualization(
              completedLessons: completedLessons,
              progress: progress,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(BuildContext context, int streak) {
    final now = DateTime.now();
    final activeDays = <int>{};
    for (int i = 0; i < streak; i++) {
      activeDays.add(now.subtract(Duration(days: i)).weekday);
    }

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'This Week',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.streakOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔥 $streak day streak',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.streakOrange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final dayNum = i + 1; // 1=Mon, 7=Sun
              final isToday = now.weekday == dayNum;
              final isPast = dayNum < now.weekday;
              final isActive = isPast
                  ? activeDays.contains(dayNum)
                  : isToday && streak > 0;

              return Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.streakOrange
                          : isToday
                              ? AppColors.streakOrange.withOpacity(0.15)
                              : AppColors.inputBg,
                      border: isToday
                          ? Border.all(
                              color: AppColors.streakOrange, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? const Text('🔥',
                              style: TextStyle(fontSize: 16))
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? AppColors.streakOrange
                                    : AppColors.textHint,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCard(BuildContext context, WidgetRef ref,
      String title, String topic, int completedLessons, int totalLessons) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎓', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Current Curriculum',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => _confirmChangeTopic(context, ref),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Change',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.primaryDark)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            topic,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalLessons > 0
                        ? completedLessons / totalLessons
                        : 0.0,
                    backgroundColor:
                        AppColors.primary.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completedLessons/$totalLessons',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, ref),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
            'You\'ll need to sign in again to access your progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmChangeTopic(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Topic?'),
        content: const Text(
            'This will clear your current curriculum. Your XP will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(curriculumProvider.notifier)
                  .resetCurriculum();
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const TopicInputScreen()),
                );
              }
            },
            child: const Text('Change Topic'),
          ),
        ],
      ),
    );
  }

  int _xpToLevel(int xp) => (xp / 500).floor() + 1;

  String _forestDescription(int completed) {
    if (completed == 0) return 'Plant your first tree by finishing a lesson!';
    if (completed < 3) return 'Your forest is just beginning to grow...';
    if (completed < 7) return 'A small grove is taking shape!';
    if (completed < 12) return 'Your forest is thriving!';
    return 'A magnificent forest! You\'re a true scholar.';
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Forest Visualization ─────────────────────────────────────────────────────

class _ForestVisualization extends StatelessWidget {
  final int completedLessons;
  final double progress;

  const _ForestVisualization({
    required this.completedLessons,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (completedLessons == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              'No lessons yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      );
    }

    return CustomPaint(
      painter: _ForestPainter(
        completedLessons: completedLessons,
        progress: progress,
      ),
      size: Size.infinite,
    );
  }
}

class _ForestPainter extends CustomPainter {
  final int completedLessons;
  final double progress;

  _ForestPainter({required this.completedLessons, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42); // Fixed seed for consistent positions
    final treeCount = math.min(completedLessons, 12);

    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A2E1A), Color(0xFF2D6A4F)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12)),
      skyPaint,
    );

    // Ground
    final groundPaint = Paint()..color = const Color(0xFF1A472A);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
        groundPaint);

    // Draw trees
    for (int i = 0; i < treeCount; i++) {
      final x = 30.0 + rng.nextDouble() * (size.width - 60);
      final baseY = size.height * 0.70 + rng.nextDouble() * size.height * 0.1;
      final height = 30.0 + rng.nextDouble() * 30;
      _drawTree(canvas, Offset(x, baseY), height);
    }

    // Moon/sun
    final moonPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width - 28, 22), 12, moonPaint);
    // Crescent
    final crescent = Paint()
      ..color = const Color(0xFF1A472A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width - 23, 18), 10, crescent);

    // Stars
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final starPositions = [
      Offset(size.width * 0.15, size.height * 0.12),
      Offset(size.width * 0.35, size.height * 0.08),
      Offset(size.width * 0.55, size.height * 0.15),
      Offset(size.width * 0.72, size.height * 0.06),
      Offset(size.width * 0.22, size.height * 0.22),
    ];
    for (final star in starPositions) {
      canvas.drawCircle(star, 1.5, starPaint);
    }
  }

  void _drawTree(Canvas canvas, Offset base, double height) {
    final trunkPaint = Paint()..color = const Color(0xFF5D4037);
    final leafPaint = Paint()..color = const Color(0xFF2D6A4F);
    final leafPaint2 = Paint()..color = const Color(0xFF52B788);

    // Trunk
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(base.dx, base.dy - 5),
          width: height * 0.12,
          height: height * 0.3),
      trunkPaint,
    );

    // Three triangle layers
    final triangleLayers = [
      {'y': base.dy - height * 0.25, 'w': height * 0.6, 'h': height * 0.4},
      {'y': base.dy - height * 0.50, 'w': height * 0.5, 'h': height * 0.38},
      {'y': base.dy - height * 0.72, 'w': height * 0.38, 'h': height * 0.34},
    ];

    for (int i = 0; i < triangleLayers.length; i++) {
      final layer = triangleLayers[i];
      final y = layer['y']!;
      final w = layer['w']! / 2;
      final h = layer['h']!;
      final path = Path()
        ..moveTo(base.dx, y - h)
        ..lineTo(base.dx - w, y)
        ..lineTo(base.dx + w, y)
        ..close();
      canvas.drawPath(path, i.isEven ? leafPaint : leafPaint2);
    }
  }

  @override
  bool shouldRepaint(_ForestPainter old) =>
      old.completedLessons != completedLessons;
}

// ─── Star Field ───────────────────────────────────────────────────────────────

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.65;
      final r = 0.8 + rng.nextDouble() * 1.2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter _) => false;
}

// ─── Forest Silhouette ────────────────────────────────────────────────────────

class _ForestSilhouette extends StatelessWidget {
  const _ForestSilhouette();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: CustomPaint(painter: _SilhouettePainter()),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A472A);

    // Draw simple tree silhouettes
    final treePositions = [0.05, 0.15, 0.25, 0.38, 0.5, 0.62, 0.74, 0.85, 0.94];
    final heights = [55.0, 70.0, 50.0, 65.0, 80.0, 60.0, 75.0, 55.0, 65.0];

    for (int i = 0; i < treePositions.length; i++) {
      final x = size.width * treePositions[i];
      final h = heights[i % heights.length];
      final baseY = size.height;

      // Triangle tree
      final path = Path()
        ..moveTo(x, baseY - h)
        ..lineTo(x - h * 0.35, baseY)
        ..lineTo(x + h * 0.35, baseY)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Fill bottom
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 10, size.width, 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SilhouettePainter _) => false;
}
