import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../../core/theme/app_colors.dart';
import '../chat/ai_chat_screen.dart';

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
  int _elapsedMinutes = 0;
  int _currentPage = 0;
  bool _isSessionActive = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _startSession() {
    setState(() => _isSessionActive = true);
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedMinutes++;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final progress = _currentPage / widget.chunk.subChunks.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSessionHeader(progress),
            _buildReadingContent(),
            _buildSessionControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chunk.episodeTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day ${widget.chunk.dayNumber} • ${widget.chunk.estimatedMinutes} min',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildTimerWidget(),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentPage + 1} of ${widget.chunk.subChunks.length} sections',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isSessionActive
            ? AppColors.primary.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: _isSessionActive ? AppColors.primary : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_elapsedMinutes}m',
            style: TextStyle(
              color: _isSessionActive ? AppColors.primary : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingContent() {
    if (widget.chunk.subChunks.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No content available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This section is being prepared',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          _progressController.forward();
        },
        itemCount: widget.chunk.subChunks.length,
        itemBuilder: (context, index) {
          final subChunk = widget.chunk.subChunks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.chunk.keyIdea.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Key Idea: ${widget.chunk.keyIdea}',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    subChunk.content,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      fontFamily: 'Georgia',
                      color: Color(0xFF2C2416),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Session timer controls
            if (!_isSessionActive && _elapsedMinutes == 0)
              ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Reading Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else if (_isSessionActive)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pauseSession,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _completeSession,
                      icon: const Icon(Icons.check),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => _startSession(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildControlButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Ask AI',
                  onTap: () => _openAIChat(),
                ),
                _buildControlButton(
                  icon: Icons.bookmark_border,
                  label: 'Bookmark',
                  onTap: () => _addBookmark(),
                ),
                _buildControlButton(
                  icon: Icons.highlight_outlined,
                  label: 'Highlight',
                  onTap: () => _addHighlight(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          book: widget.book,
          currentPage: _currentPage + 1,
          currentChunk: widget.chunk,
        ),
      ),
    );
  }

  void _addBookmark() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bookmark added'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to bookmarks
          },
        ),
      ),
    );
  }

  void _addHighlight() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap text to highlight it'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _completeSession() {
    _pauseSession();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionCompleteDialog(
        chunk: widget.chunk,
        elapsedMinutes: _elapsedMinutes,
        pagesRead: _currentPage + 1,
        onConfirm: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Close reading session
        },
        onContinue: () {
          Navigator.pop(context); // Close dialog
          _startSession(); // Resume session
        },
      ),
    );
  }
}

class SessionCompleteDialog extends StatelessWidget {
  final BookChunk chunk;
  final int elapsedMinutes;
  final int pagesRead;
  final VoidCallback onConfirm;
  final VoidCallback onContinue;

  const SessionCompleteDialog({
    super.key,
    required this.chunk,
    required this.elapsedMinutes,
    required this.pagesRead,
    required this.onConfirm,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final xpEarned = (elapsedMinutes * 5) + (pagesRead * 10);
    final streakBonus = 25;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          _buildStatRow(Icons.timer_outlined, 'Time spent', '$elapsedMinutes minutes'),
          const SizedBox(height: 12),
          _buildStatRow(Icons.menu_book, 'Sections read', '$pagesRead of ${chunk.subChunks.length}'),
          const SizedBox(height: 12),
          _buildStatRow(Icons.stars, 'XP earned', '+$xpEarned', color: AppColors.xpGold),
          const SizedBox(height: 12),
          _buildStatRow(Icons.local_fire_department, 'Streak bonus', '+$streakBonus', color: AppColors.streakFire),

          const SizedBox(height: 24),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: AppColors.xpGold),
                const SizedBox(width: 8),
                Text(
                  'Total: +${xpEarned + streakBonus} XP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.xpGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: const Text('Continue Reading'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Progress'),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
          ),
        ),
      ],
    );
  }
}
