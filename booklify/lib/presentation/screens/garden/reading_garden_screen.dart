import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/book.dart';
import '../../../widgets/garden/tree_painter.dart';
import '../../providers/garden_provider.dart';
import '../../providers/user_stats_provider.dart';

class ReadingGardenScreen extends ConsumerStatefulWidget {
  const ReadingGardenScreen({super.key});

  @override
  ConsumerState<ReadingGardenScreen> createState() =>
      _ReadingGardenScreenState();
}

class _ReadingGardenScreenState
    extends ConsumerState<ReadingGardenScreen>
    with TickerProviderStateMixin {
  late AnimationController _treeController;
  late AnimationController _weatherController;

  @override
  void initState() {
    super.initState();
    _treeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _weatherController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _treeController.forward();
  }

  @override
  void dispose() {
    _treeController.dispose();
    _weatherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final weather = ref.watch(gardenWeatherProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _weatherColors(weather),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, statsAsync),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTreeView(progress, weather),
                      _buildStatsBar(statsAsync),
                      if (progress != null && progress.currentDay > 0)
                        _buildStreakCard(progress),
                      _buildTip(progress),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AsyncValue<UserStats> statsAsync) {
    final stats = statsAsync.valueOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Reading Garden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Nurture your mind, grow your tree',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12),
              ),
            ],
          ),
          // Level badge
          if (stats != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    'Level ${stats.level}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Tree canvas ────────────────────────────────────────────────────────────

  Widget _buildTreeView(Progress? progress, GardenWeather weather) {
    final sessionsCompleted = progress?.currentDay ?? 0;
    final totalTarget =
        (progress?.totalDays ?? 7).clamp(1, 999);
    final growthStage =
        (sessionsCompleted / totalTarget).clamp(0.02, 1.0);

    return GestureDetector(
      onTap: progress != null && sessionsCompleted > 0
          ? () => _showDetails(progress)
          : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CustomPaint(
            painter: TreePainter(
              growthStage: growthStage,
              completedDays: sessionsCompleted,
              level: progress?.level ?? 1,
              animation: _treeController,
              weather: weather,
            ),
            child: sessionsCompleted == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🌱 Your tree is waiting — start reading!',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F46E5)),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ── Stats bar ──────────────────────────────────────────────────────────────

  Widget _buildStatsBar(AsyncValue<UserStats> statsAsync) {
    final stats = statsAsync.valueOrNull;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          _statCard(
              icon: '⭐',
              label: 'Level',
              value: '${stats?.level ?? 1}'),
          const SizedBox(width: 10),
          _statCard(
              icon: '✨',
              label: 'XP',
              value: '${stats?.xp ?? 0}'),
          const SizedBox(width: 10),
          _statCard(
              icon: '🔥',
              label: 'Streak',
              value: '${stats?.streakDays ?? 0}d'),
          const SizedBox(width: 10),
          _statCard(
              icon: '📖',
              label: 'Sessions',
              value: '${stats?.totalSessionsCompleted ?? 0}'),
        ],
      ),
    );
  }

  Widget _statCard(
      {required String icon,
      required String label,
      required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ── XP progress ────────────────────────────────────────────────────────────

  Widget _buildStreakCard(Progress progress) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP to Level ${progress.level + 1}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              Text(
                '${progress.xp % 100} / 100',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress.xp % 100) / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tip card ───────────────────────────────────────────────────────────────

  Widget _buildTip(Progress? progress) {
    final sessions = progress?.currentDay ?? 0;
    String tip;
    if (sessions == 0) {
      tip = '💡 Add a book in the Library tab, then start your first reading session to grow your tree.';
    } else if (sessions < 3) {
      tip = '💡 Read 3 days in a row to earn the "On Fire" achievement!';
    } else if ((progress?.streakDays ?? 0) == 0) {
      tip = '💧 Your tree is looking a bit dry — come back and read today!';
    } else {
      tip = '🌳 Your garden is thriving! Keep the streak alive.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        tip,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            height: 1.5),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Color> _weatherColors(GardenWeather w) {
    switch (w) {
      case GardenWeather.sunny:
        return [const Color(0xFF4F46E5), const Color(0xFF0284C7)];
      case GardenWeather.cloudy:
        return [const Color(0xFF6B21A8), const Color(0xFF4F46E5)];
      case GardenWeather.stormy:
        return [const Color(0xFF374151), const Color(0xFF6B21A8)];
    }
  }

  void _showDetails(Progress progress) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GardenDetailsSheet(progress: progress),
    );
  }
}

// ─── Details sheet ────────────────────────────────────────────────────────────

class _GardenDetailsSheet extends StatelessWidget {
  final Progress progress;
  const _GardenDetailsSheet({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Garden Stats',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _row('⭐ Level', '${progress.level}'),
          _row('✨ Total XP', '${progress.xp}'),
          _row('📖 Sessions completed', '${progress.currentDay}'),
          _row('🔥 Current streak', '${progress.streakDays} days'),
          _row(
              '📊 Progress',
              '${(progress.progressPercent * 100).toInt()}%'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B21A8),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
