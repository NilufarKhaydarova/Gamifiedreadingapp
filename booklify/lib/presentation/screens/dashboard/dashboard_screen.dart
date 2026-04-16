import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garden_provider.dart';
import '../reading/reading_session_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final progressAsync = ref.watch(progressProvider);
    final book = ref.watch(currentBookProvider);
    final challengeAsync = ref.watch(dailyChallengeProvider);
    final _displayName = user?.displayName ?? '';
    final displayInitial =
        _displayName.isEmpty ? 'R' : _displayName.substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(progressProvider);
            ref.invalidate(dailyChallengeProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()},',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            user?.displayName ?? 'Reader',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          displayInitial,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Daily Challenge Card
              SliverToBoxAdapter(
                child: challengeAsync.when(
                  data: (challenge) => _buildDailyChallengeCard(
                      context, challenge),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Progress Card
              SliverToBoxAdapter(
                child: progressAsync.when(
                  data: (progress) {
                    if (progress == null) {
                      return _buildNoBookCard(context);
                    }
                    return _buildProgressCard(context, progress, book, ref);
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Stats Row
              SliverToBoxAdapter(
                child: progressAsync.when(
                  data: (progress) {
                    if (progress == null) return const SizedBox.shrink();
                    return _buildStatsRow(context, progress);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildDailyChallengeCard(
      BuildContext context, Map<String, dynamic> challenge) {
    if (challenge.isEmpty) return const SizedBox.shrink();

    final target = challenge['target_minutes'] as int? ?? 15;
    final completed = challenge['completed_minutes'] as int? ?? 0;
    final isDone = challenge['completed'] as bool? ?? false;
    final progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDone
              ? [Colors.green.shade400, Colors.green.shade600]
              : [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.flag_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Challenge",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Done!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isDone
                ? 'Great job! You read today!'
                : 'Read for $target minutes today',
            style: TextStyle(
                color: Colors.white.withOpacity(0.9), fontSize: 14),
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
            '$completed / $target min',
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBookCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.library_books_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No book selected',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Library to add and select a book to start reading.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      BuildContext context, Progress progress, Book? book, WidgetRef ref) {
    final nextChunk =
        book != null && book.chunks.isNotEmpty && progress.currentDay < book.chunks.length
            ? book.chunks[progress.currentDay]
            : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book?.title ?? 'Reading in Progress',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book?.author != null && book!.author.isNotEmpty)
                      Text(
                        book.author,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),
              _buildXPBadge(context, progress),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${progress.currentDay} of ${progress.totalDays}',
                style: TextStyle(
                    color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
              Text(
                '${(progress.progressPercent * 100).toInt()}%',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.progressPercent,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 10,
            ),
          ),
          if (nextChunk != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              "Next: ${nextChunk.episodeTitle}",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '~${nextChunk.estimatedMinutes} min  •  ${nextChunk.difficulty.name}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadingSessionScreen(
                      chunk: nextChunk,
                      book: book!,
                    ),
                  ),
                ).then((_) {
                  ref.invalidate(progressProvider);
                }),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue Reading'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildXPBadge(BuildContext context, Progress progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.xpGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.xpGold.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            'Lvl ${progress.level}',
            style: const TextStyle(
              color: AppColors.xpGold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${progress.xp} XP',
            style: TextStyle(
                color: AppColors.xpGold.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Progress progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          _buildStatTile(
            context,
            icon: Icons.local_fire_department,
            value: '${progress.streakDays}',
            label: 'Day Streak',
            color: AppColors.streakFire,
          ),
          const SizedBox(width: 12),
          _buildStatTile(
            context,
            icon: Icons.check_circle_outline,
            value: '${progress.completedDays.length}',
            label: 'Days Done',
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatTile(
            context,
            icon: Icons.bolt,
            value: '${progress.xp}',
            label: 'Total XP',
            color: AppColors.xpGold,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  color: color.withOpacity(0.8), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
