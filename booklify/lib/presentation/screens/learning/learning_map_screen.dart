import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/garden_provider.dart';
import '../../../data/models/book.dart';
import '../reading/reading_session_screen.dart';

const _kGrad1 = Color(0xFF6B21A8);
const _kGrad2 = Color(0xFF4F46E5);
const _kGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kGrad1, _kGrad2],
);

class LearningMapScreen extends ConsumerWidget {
  const LearningMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final notifier = ref.read(booksProvider.notifier);
    final active = notifier.getActiveBook();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: _kGrad,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your personalised reading journey',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          booksAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (books) {
              if (books.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyState(),
                );
              }
              if (active == null || active.chunks.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyState(),
                );
              }
              return _ChunkList(book: active);
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: _kGrad,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'No learning map yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a book and generate your reading plan to see your journey here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChunkList extends ConsumerWidget {
  final Book book;
  const _ChunkList({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chunks = book.chunks;
    final completedCount = chunks.where((c) => c.completed).length;
    final progress = chunks.isEmpty ? 0.0 : completedCount / chunks.length;

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      book.author,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedCount / ${chunks.length} episodes',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kGrad1,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _kGrad1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: _kGrad1.withValues(alpha: 0.12),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_kGrad1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Chunk nodes
              ...chunks.asMap().entries.map((entry) {
                final index = entry.key;
                final chunk = entry.value;
                final isLast = index == chunks.length - 1;
                final isCurrent = !chunk.completed &&
                    chunks.where((c) => !c.completed).firstOrNull?.id ==
                        chunk.id;
                return _ChunkNode(
                  chunk: chunk,
                  isCompleted: chunk.completed,
                  isCurrent: isCurrent,
                  isLast: isLast,
                  onTap: isCurrent
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReadingSessionScreen(
                                  chunk: chunk, book: book),
                            ),
                          )
                      : null,
                );
              }),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ChunkNode extends StatelessWidget {
  final BookChunk chunk;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final VoidCallback? onTap;

  const _ChunkNode({
    required this.chunk,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    this.onTap,
  });

  Color get _nodeColor {
    if (isCompleted) return const Color(0xFF059669);
    if (isCurrent) return _kGrad1;
    return Colors.grey[300]!;
  }

  IconData get _nodeIcon {
    if (isCompleted) return Icons.check_rounded;
    if (isCurrent) return Icons.play_arrow_rounded;
    return Icons.lock_outline_rounded;
  }

  String get _difficultyLabel {
    switch (chunk.difficulty) {
      case Difficulty.light:
        return '🌱 Light';
      case Difficulty.moderate:
        return '📘 Moderate';
      case Difficulty.dense:
        return '🔥 Dense';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? _nodeColor : Colors.grey[200],
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: _kGrad1, width: 2.5)
                    : null,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: _kGrad1.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _nodeIcon,
                color: isCompleted || isCurrent ? Colors.white : Colors.grey[400],
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted ? const Color(0xFF059669) : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content card
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isCurrent
                      ? Border.all(color: _kGrad1.withValues(alpha: 0.4))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Day ${chunk.dayNumber}: ${chunk.episodeTitle}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCompleted || isCurrent
                                  ? const Color(0xFF1E1B4B)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                        Text(
                          _difficultyLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent || isCompleted) ...[
                      const SizedBox(height: 4),
                      Text(
                        chunk.keyIdea,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '~${chunk.estimatedMinutes} min',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: _kGrad,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Start →',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
