import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_stats_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static const _kGrad1 = Color(0xFF6B21A8);
  static const _kGrad2 = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => _buildBody(context, stats),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserStats stats) {
    final earned = stats.earnedAchievementIds;
    final categories = ['sessions', 'streak', 'level', 'books', 'xp'];
    final categoryLabels = {
      'sessions': '📖 Sessions',
      'streak': '🔥 Streaks',
      'level': '⭐ Levels',
      'books': '📚 Library',
      'xp': '✨ XP Milestones',
    };

    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kGrad1, _kGrad2],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${earned.length} of ${kAllAchievements.length} unlocked',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14),
                ),
                const SizedBox(height: 20),
                // Overall progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: kAllAchievements.isEmpty
                        ? 0
                        : earned.length / kAllAchievements.length,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _headerStat('${stats.level}', 'Level'),
                    _headerStat('${stats.xp}', 'Total XP'),
                    _headerStat('${stats.streakDays}🔥', 'Streak'),
                    _headerStat(
                        '${stats.totalSessionsCompleted}', 'Sessions'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Achievement categories ─────────────────────────────────────────
        for (final cat in categories) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                categoryLabels[cat] ?? cat,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _AchievementRow(
              defs: kAllAchievements
                  .where((a) => a.category == cat)
                  .toList(),
              earned: earned,
              stats: stats,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _headerStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11)),
      ],
    );
  }
}

// ─── Sliver row of achievement cards ─────────────────────────────────────────

class _AchievementRow extends StatelessWidget {
  final List<AchievementDef> defs;
  final List<String> earned;
  final UserStats stats;

  const _AchievementRow(
      {required this.defs, required this.earned, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, i) => _AchievementCard(
          def: defs[i],
          isEarned: earned.contains(defs[i].id),
          progress: _progressFor(defs[i]),
        ),
        childCount: defs.length,
      ),
    );
  }

  (int, int)? _progressFor(AchievementDef def) {
    switch (def.id) {
      case 'first_session':
        return (stats.totalSessionsCompleted.clamp(0, 1), 1);
      case 'sessions_5':
        return (stats.totalSessionsCompleted.clamp(0, 5), 5);
      case 'sessions_10':
        return (stats.totalSessionsCompleted.clamp(0, 10), 10);
      case 'sessions_25':
        return (stats.totalSessionsCompleted.clamp(0, 25), 25);
      case 'streak_3':
        return (stats.streakDays.clamp(0, 3), 3);
      case 'streak_7':
        return (stats.streakDays.clamp(0, 7), 7);
      case 'streak_14':
        return (stats.streakDays.clamp(0, 14), 14);
      case 'level_5':
        return (stats.level.clamp(0, 5), 5);
      case 'level_10':
        return (stats.level.clamp(0, 10), 10);
      case 'first_book':
        return (stats.totalBooksStarted.clamp(0, 1), 1);
      case 'books_3':
        return (stats.totalBooksStarted.clamp(0, 3), 3);
      case 'book_finished':
        return (stats.totalBooksFinished.clamp(0, 1), 1);
      case 'xp_500':
        return (stats.xp.clamp(0, 500), 500);
      case 'xp_1000':
        return (stats.xp.clamp(0, 1000), 1000);
      default:
        return null;
    }
  }
}

// ─── Individual card ──────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final AchievementDef def;
  final bool isEarned;
  final (int, int)? progress;

  const _AchievementCard({
    required this.def,
    required this.isEarned,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    const earned1 = Color(0xFF6B21A8);
    final lockedFg = const Color(0xFFBBB9CC);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEarned ? Colors.white : const Color(0xFFF0EFF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned
              ? earned1.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: earned1.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEarned ? def.emoji : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
              if (isEarned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: earned1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${def.xpReward}xp',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: earned1),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                def.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEarned ? const Color(0xFF1E1B4B) : lockedFg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isEarned && progress != null) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress!.$2 > 0
                        ? progress!.$1 / progress!.$2
                        : 0.0,
                    minHeight: 4,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(earned1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${progress!.$1} / ${progress!.$2}',
                  style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                ),
              ] else if (isEarned) ...[
                Text(
                  def.description,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
