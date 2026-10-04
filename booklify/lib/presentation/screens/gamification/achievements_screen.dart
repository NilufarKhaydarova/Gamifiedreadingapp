import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/user_stats_provider.dart';

/// Every reading achievement, earned or not. Driven by [userStatsProvider],
/// which reading sessions and finished books update.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: statsAsync.when(
        data: (stats) {
          final earned = stats.earnedAchievementIds.toSet();
          final unlockedCount =
              kAllAchievements.where((a) => earned.contains(a.id)).length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(unlockedCount, kAllAchievements.length),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final achievement = kAllAchievements[index];
                      return _AchievementCard(
                        achievement: achievement,
                        isUnlocked: earned.contains(achievement.id),
                      );
                    },
                    childCount: kAllAchievements.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.xpGold.withValues(alpha: 0.8),
              AppColors.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.xpGold.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlocked / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Achievements Unlocked',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% complete',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Achievement Card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final AchievementDef achievement;
  final bool isUnlocked;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor();
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: isUnlocked
              ? Border.all(color: color.withValues(alpha: 0.4), width: 2)
              : Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _badge(60, 28),
              const SizedBox(height: 12),
              Text(
                achievement.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isUnlocked ? AppColors.textPrimary : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 11,
                  color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.xpGold.withValues(alpha: 0.15)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? AppColors.xpGold : Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (isUnlocked)
                Text(
                  '✓ Unlocked',
                  style: TextStyle(
                      fontSize: 10, color: color, fontWeight: FontWeight.w600),
                )
              else
                Icon(Icons.lock_outline, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// The achievement's emoji in a tinted circle (greyed out while locked).
  Widget _badge(double size, double emojiSize) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked
            ? _categoryColor().withValues(alpha: 0.15)
            : Colors.grey[100],
      ),
      child: Opacity(
        opacity: isUnlocked ? 1 : 0.35,
        child: Text(achievement.emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }

  Color _categoryColor() {
    switch (achievement.category) {
      case 'streak':
        return AppColors.streakFire;
      case 'sessions':
        return Colors.blue;
      case 'books':
        return Colors.teal;
      case 'level':
      case 'xp':
      default:
        return AppColors.xpGold;
    }
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge(80, 38),
            const SizedBox(height: 16),
            Text(achievement.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.xpGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppColors.xpGold),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.xpReward} XP Reward',
                    style: const TextStyle(
                        color: AppColors.xpGold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isUnlocked
                  ? 'Unlocked — reward added to your XP'
                  : 'Keep reading to unlock this achievement!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
