import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/book_provider.dart';
import '../../providers/user_stats_provider.dart';
import '../chat/ai_chat_screen.dart';

// ─── Reading Session ──────────────────────────────────────────────────────────

class ReadingSessionScreen extends ConsumerStatefulWidget {
  final BookChunk chunk;
  final Book book;

  const ReadingSessionScreen({
    super.key,
    required this.chunk,
    required this.book,
  });

  @override
  ConsumerState<ReadingSessionScreen> createState() =>
      _ReadingSessionScreenState();
}

class _ReadingSessionScreenState extends ConsumerState<ReadingSessionScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  int _currentPage = 0;
  bool _isSessionActive = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Auto-start reading
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  void _startSession() {
    if (_isSessionActive) return;
    setState(() => _isSessionActive = true);
    _sessionTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _pauseSession() {
    setState(() => _isSessionActive = false);
    _sessionTimer?.cancel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _elapsedMinutes => (_elapsedSeconds / 60).ceil().clamp(1, 999);

  // ── Save & complete ────────────────────────────────────────────────────────

  Future<void> _completeSession() async {
    _pauseSession();
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final sectionsRead = _currentPage + 1;
      final xpEarned =
          (_elapsedMinutes * 5) + (sectionsRead * 10) + 25; // +25 streak bonus

      // Persist progress
      final newAchievements = await ref
          .read(userStatsProvider.notifier)
          .completeSession(xpEarned: xpEarned);

      await ref
          .read(booksProvider.notifier)
          .markChunkComplete(widget.book.id, widget.chunk.id);

      final stats = ref.read(userStatsProvider).valueOrNull;

      if (mounted) {
        setState(() => _isSaving = false);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SessionCompleteDialog(
            chunk: widget.chunk,
            elapsedMinutes: _elapsedMinutes,
            sectionsRead: sectionsRead,
            xpEarned: xpEarned,
            newLevel: stats?.level,
            newAchievements: newAchievements,
            onDone: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close session
            },
            onContinue: () {
              Navigator.pop(context); // close dialog
              _startSession();
            },
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final progress = widget.chunk.subChunks.isEmpty
        ? 0.0
        : (_currentPage + 1) / widget.chunk.subChunks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(progress),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.arrow_back_ios_new, size: 18,
                      color: Color(0xFF6B21A8)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chunk.episodeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.book.title} · Day ${widget.chunk.dayNumber}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Timer chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isSessionActive
                      ? const Color(0xFF6B21A8).withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14,
                        color: _isSessionActive
                            ? const Color(0xFF6B21A8)
                            : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _timerText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isSessionActive
                            ? const Color(0xFF6B21A8)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6B21A8)),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentPage + 1} / ${widget.chunk.subChunks.isEmpty ? 1 : widget.chunk.subChunks.length} sections',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              Text(
                '~${widget.chunk.estimatedMinutes} min read',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    if (widget.chunk.subChunks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No content yet',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('This section is still being prepared.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) {
        setState(() => _currentPage = i);
        _progressController.forward(from: 0);
      },
      itemCount: widget.chunk.subChunks.length,
      itemBuilder: (_, i) => _buildPage(widget.chunk.subChunks[i]),
    );
  }

  Widget _buildPage(SubChunk sub) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key idea banner
          if (widget.chunk.keyIdea.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.chunk.keyIdea,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Main reading text
          Text(
            sub.content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.75,
              color: Color(0xFF2C2416),
              fontFamily: 'Georgia',
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 40),

          // Swipe hint
          if (widget.chunk.subChunks.length > 1)
            Center(
              child: Text(
                _currentPage < widget.chunk.subChunks.length - 1
                    ? 'Swipe left for next section →'
                    : '✓ Last section — tap Complete when done',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action
          Row(
            children: [
              Expanded(
                child: _isSessionActive
                    ? _footerBtn(
                        label: 'Pause',
                        icon: Icons.pause_rounded,
                        color: Colors.orange,
                        onTap: _pauseSession,
                      )
                    : _footerBtn(
                        label: 'Resume',
                        icon: Icons.play_arrow_rounded,
                        color: const Color(0xFF059669),
                        onTap: _startSession,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _footerBtn(
                  label: _isSaving ? 'Saving…' : 'Complete ✓',
                  icon: _isSaving ? Icons.hourglass_empty : Icons.check_rounded,
                  color: const Color(0xFF6B21A8),
                  onTap: _isSaving ? null : _completeSession,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Secondary actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _iconAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Ask AI',
                  onTap: _openChat),
              _iconAction(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Bookmark',
                  onTap: _addBookmark),
              _iconAction(
                  icon: Icons.format_quote_rounded,
                  label: 'Highlight',
                  onTap: _addHighlight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerBtn({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _iconAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF6B21A8), size: 22),
            const SizedBox(height: 3),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIChatScreen(
          book: widget.book,
          currentPage: _currentPage + 1,
          currentChunk: widget.chunk,
        ),
      ),
    );
  }

  void _addBookmark() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Bookmark added ✓'),
      backgroundColor: const Color(0xFF6B21A8),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _addHighlight() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Long-press any text to highlight'),
      duration: Duration(seconds: 2),
    ));
  }
}

// ─── Session Complete Dialog ──────────────────────────────────────────────────

class _SessionCompleteDialog extends StatelessWidget {
  final BookChunk chunk;
  final int elapsedMinutes;
  final int sectionsRead;
  final int xpEarned;
  final int? newLevel;
  final List<String> newAchievements;
  final VoidCallback onDone;
  final VoidCallback onContinue;

  const _SessionCompleteDialog({
    required this.chunk,
    required this.elapsedMinutes,
    required this.sectionsRead,
    required this.xpEarned,
    required this.newAchievements,
    required this.onDone,
    required this.onContinue,
    this.newLevel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 18),
          const Text('Session Complete! 🎉',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B))),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('⏱', '$elapsedMinutes min', 'Time'),
              _divider(),
              _stat('📄', '$sectionsRead', 'Sections'),
              _divider(),
              _stat('⭐', '+$xpEarned', 'XP'),
            ],
          ),

          // Level up
          if (newLevel != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌟 ', style: TextStyle(fontSize: 18)),
                  Text('Level $newLevel!',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309))),
                ],
              ),
            ),
          ],

          // New achievements
          if (newAchievements.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...newAchievements.take(2).map((id) {
              final def = kAllAchievements.firstWhere(
                (a) => a.id == id,
                orElse: () => const AchievementDef(
                    id: '', emoji: '🏅', title: 'Achievement',
                    description: '', xpReward: 0, category: ''),
              );
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(def.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Achievement Unlocked!',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                          Text(def.title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B21A8))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: Text('Keep Reading',
              style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B21A8),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B))),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 40, color: Colors.grey[200]);
}
