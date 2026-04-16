import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/achievement.dart';
import '../../providers/auth_provider.dart';

// Providers for achievements
final _allAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getAchievements();
});

final _userAchievementsProvider =
    FutureProvider<List<Achievement>>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return [];
  final db = ref.read(databaseServiceProvider);
  return await db.getUserAchievements(user.id);
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(_allAchievementsProvider);
    final unlockedAsync = ref.watch(_userAchievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: allAsync.when(
        data: (all) {
          return unlockedAsync.when(
            data: (unlocked) {
              final unlockedIds = unlocked.map((a) => a.id).toSet();
              final unlockedCount = unlockedIds.length;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, unlockedCount, all.length),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final achievement = all[index];
                          final isUnlocked =
                              unlockedIds.contains(achievement.id);
                          final unlockedData = isUnlocked
                              ? unlocked.firstWhere(
                                  (a) => a.id == achievement.id)
                              : null;
                          return _AchievementCard(
                            achievement: achievement,
                            isUnlocked: isUnlocked,
                            unlockedAt: unlockedData?.unlockedAt,
                          );
                        },
                        childCount: all.length,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.xpGold.withOpacity(0.8),
              AppColors.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.xpGold.withOpacity(0.3),
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
                Column(
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
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
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
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: isUnlocked
              ? Border.all(color: _categoryColor().withOpacity(0.4), width: 2)
              : Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: _categoryColor().withOpacity(0.2),
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
              // Icon circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? _categoryColor().withOpacity(0.15)
                      : Colors.grey[100],
                ),
                child: Icon(
                  _categoryIcon(),
                  size: 30,
                  color: isUnlocked ? _categoryColor() : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                achievement.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isUnlocked
                      ? AppColors.textPrimary
                      : Colors.grey[500],
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

              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.xpGold.withOpacity(0.15)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${achievement.xpReward ?? 0} XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? AppColors.xpGold : Colors.grey[400],
                  ),
                ),
              ),

              if (isUnlocked && unlockedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  '✓ Unlocked',
                  style: TextStyle(
                      fontSize: 10,
                      color: _categoryColor(),
                      fontWeight: FontWeight.w600),
                ),
              ] else if (!isUnlocked) ...[
                const SizedBox(height: 6),
                Icon(Icons.lock_outline, size: 14, color: Colors.grey[400]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor() {
    switch (achievement.category) {
      case AchievementCategory.streak:
        return AppColors.streakFire;
      case AchievementCategory.readingSpeed:
        return Colors.blue;
      case AchievementCategory.comprehension:
        return Colors.purple;
      case AchievementCategory.social:
        return Colors.teal;
      case AchievementCategory.level:
        return AppColors.xpGold;
    }
  }

  IconData _categoryIcon() {
    switch (achievement.category) {
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.readingSpeed:
        return Icons.speed;
      case AchievementCategory.comprehension:
        return Icons.psychology;
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.level:
        return Icons.stars;
    }
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? _categoryColor().withOpacity(0.15)
                    : Colors.grey[100],
              ),
              child: Icon(
                _categoryIcon(),
                size: 40,
                color: isUnlocked ? _categoryColor() : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(achievement.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
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
                color: AppColors.xpGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppColors.xpGold),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.xpReward ?? 0} XP Reward',
                    style: const TextStyle(
                        color: AppColors.xpGold,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Unlocked on ${_formatDate(unlockedAt!)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ] else if (!isUnlocked) ...[
              const SizedBox(height: 12),
              const Text(
                'Keep reading to unlock this achievement!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
