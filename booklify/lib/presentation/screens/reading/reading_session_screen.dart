import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../../data/services/adaptive_rag_service.dart';
import '../../../data/services/ai_provider_service.dart';
import '../../../data/services/claude_service.dart';
import '../../providers/garden_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_stats_provider.dart';

// ─── Reading Themes ────────────────────────────────────────────────────────────

enum ReadingTheme { white, sepia, dark }

extension ReadingThemeExt on ReadingTheme {
  Color get bg => switch (this) {
        ReadingTheme.white => const Color(0xFFFFFFFF),
        ReadingTheme.sepia => const Color(0xFFFAF3E0),
        ReadingTheme.dark => const Color(0xFF1A1A2E),
      };
  Color get text => switch (this) {
        ReadingTheme.white => const Color(0xFF2C2416),
        ReadingTheme.sepia => const Color(0xFF3B2A1A),
        ReadingTheme.dark => const Color(0xFFE8E0D0),
      };
  Color get surface => switch (this) {
        ReadingTheme.white => Colors.white,
        ReadingTheme.sepia => const Color(0xFFF5EBCF),
        ReadingTheme.dark => const Color(0xFF16213E),
      };
  Color get accent => const Color(0xFF6B21A8);
  String get label => switch (this) {
        ReadingTheme.white => 'Light',
        ReadingTheme.sepia => 'Sepia',
        ReadingTheme.dark => 'Dark',
      };
}

// ─── Reading Session Screen ───────────────────────────────────────────────────

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
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _isSessionActive = false;
  bool _isSaving = false;

  // Analytics
  double _scrollCompletion = 0;
  int _wordsRead = 0;

  // Pagination
  int _currentPage = 0;
  List<String> _pages = [];
  String? _cachedText;
  double? _lastFontSize;

  // Highlight
  String? _selectedText;

  // Settings
  ReadingTheme _theme = ReadingTheme.white;
  double _fontSize = 17;
  bool _showSettings = false;

  // Session data (persisted on complete)
  final List<String> _sessionHighlights = [];
  final List<String> _sessionAiQuestions = [];

  // Highlights loaded from DB — rendered inline in yellow
  List<String> _loadedHighlights = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
      _loadExistingHighlights();
    });
  }

  Future<void> _loadExistingHighlights() async {
    final user = ref.read(authUserProvider);
    final db = ref.read(databaseServiceProvider);
    if (user == null) return;
    try {
      final rows = await db.getHighlights(user.id, widget.book.id);
      final forThisChunk = rows
          .where((r) => r['chunk_id'] == widget.chunk.id)
          .map((r) => r['text'] as String)
          .where((t) => t.isNotEmpty)
          .toList();
      if (mounted && forThisChunk.isNotEmpty) {
        setState(() => _loadedHighlights = forThisChunk);
      }
    } catch (_) {
      // Non-critical — highlights just won't be pre-shown
    }
  }

  void _onPageChanged(int page) {
    final total = _pages.length;
    final pct = total <= 1 ? 1.0 : page / (total - 1).toDouble();
    setState(() {
      _currentPage = page;
      _scrollCompletion = pct;
      _wordsRead = (_totalWords * pct).round();
    });
  }

  /// Split [text] into pages by paragraph, aiming for [charsPerPage] chars each.
  List<String> _paginateText(String text, int charsPerPage) {
    final paras = text.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).toList();
    if (paras.isEmpty) return [text];
    final pages = <String>[];
    final buf = StringBuffer();
    for (final para in paras) {
      final t = para.trim();
      if (buf.isNotEmpty && buf.length + t.length + 2 > charsPerPage) {
        pages.add(buf.toString().trim());
        buf.clear();
      }
      if (buf.isNotEmpty) buf.write('\n\n');
      buf.write(t);
    }
    if (buf.isNotEmpty) pages.add(buf.toString().trim());
    return pages.isEmpty ? [text] : pages;
  }

  void _startSession() {
    if (_isSessionActive) return;
    setState(() => _isSessionActive = true);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    _sessionTimer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _elapsedMinutes => (_elapsedSeconds / 60).ceil().clamp(1, 999);

  int get _totalWords => widget.chunk.subChunks
      .fold(0, (s, c) => s + (c.wordCount ?? c.content.split(' ').length));

  int get _wpm {
    if (_elapsedSeconds < 15) return 0;
    return (_wordsRead / (_elapsedSeconds / 60)).round().clamp(0, 1000);
  }

  // ── Complete session ────────────────────────────────────────────────────────

  Future<void> _completeSession() async {
    _pauseSession();
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = ref.read(authUserProvider);
    final db = ref.read(databaseServiceProvider);

    try {
      // Save reading analytics
      if (user != null && _elapsedSeconds > 10) {
        await db.saveReadingAnalytics(
          userId: user.id,
          bookId: widget.book.id,
          chunkId: widget.chunk.id,
          wpm: _wpm,
          timeSeconds: _elapsedSeconds,
          scrollCompletion: _scrollCompletion,
        );

        // Update adaptive profile
        final rag = AdaptiveRagService(db);
        await rag.updateProfileAfterSession(
          userId: user.id,
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          sessionHighlights: _sessionHighlights,
          sessionAiQuestions: _sessionAiQuestions,
          sessionWpm: _wpm,
          scrollCompletion: _scrollCompletion,
        );
      }

      final xpEarned = (_elapsedMinutes * 5) + 25;
      final newAchievements = await ref
          .read(userStatsProvider.notifier)
          .completeSession(xpEarned: xpEarned);

      await ref
          .read(booksProvider.notifier)
          .markChunkComplete(widget.book.id, widget.chunk.id);

      final stats = ref.read(userStatsProvider).value;

      if (mounted) {
        setState(() => _isSaving = false);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SessionCompleteDialog(
            chunk: widget.chunk,
            elapsedMinutes: _elapsedMinutes,
            wpm: _wpm,
            xpEarned: xpEarned,
            highlights: _sessionHighlights.length,
            aiQuestions: _sessionAiQuestions.length,
            scrollCompletion: _scrollCompletion,
            newLevel: stats?.level,
            newAchievements: newAchievements,
            onDone: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            onContinue: () {
              Navigator.pop(context);
              _startSession();
            },
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showSettings) _buildSettingsBar(),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _theme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 18, color: _theme.accent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chunk.episodeTitle,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _theme.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.book.title} · Day ${widget.chunk.dayNumber}',
                      style: TextStyle(
                          fontSize: 11,
                          color: _theme.text.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isSessionActive ? _pauseSession : _startSession,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isSessionActive
                        ? _theme.accent.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSessionActive ? Icons.timer_outlined : Icons.pause_circle_outline,
                        size: 14,
                        color: _isSessionActive ? _theme.accent : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(_timerText,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isSessionActive ? _theme.accent : Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _showSettings = !_showSettings),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.text_fields_rounded,
                      size: 20,
                      color: _showSettings
                          ? _theme.accent
                          : _theme.text.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _scrollCompletion,
              minHeight: 4,
              backgroundColor: _theme.text.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(_theme.accent),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('~${widget.chunk.estimatedMinutes} min read',
                  style: TextStyle(
                      fontSize: 10, color: _theme.text.withValues(alpha: 0.45))),
              if (_wpm > 0)
                Text('$_wpm wpm',
                    style: TextStyle(
                        fontSize: 10, color: _theme.accent.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsBar() {
    return Container(
      color: _theme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_size_rounded,
                  size: 16, color: _theme.text.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 14, max: 24, divisions: 10,
                  activeColor: _theme.accent,
                  inactiveColor: _theme.text.withValues(alpha: 0.1),
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
              Text('${_fontSize.round()}',
                  style: TextStyle(
                      fontSize: 12, color: _theme.text.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  size: 16, color: _theme.text.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              ...ReadingTheme.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _theme = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: t.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _theme == t ? _theme.accent : Colors.grey.withValues(alpha: 0.3),
                            width: _theme == t ? 2 : 1,
                          ),
                        ),
                        child: Text(t.label,
                            style: TextStyle(
                                fontSize: 12,
                                color: t.text,
                                fontWeight: _theme == t ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // Strips PDF page-header artifacts like "Crime and Punishment\n61 of 967\n".
  String _cleanText(String raw) {
    var t = raw.replaceAll(
        RegExp(r'^.{1,120}\n\d+ of \d+\n', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\d+ of \d+\s*$', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\s*\d+\s*$', multiLine: true), '');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return t.trim();
  }

  Widget _buildContent() {
    final rawText = widget.chunk.subChunks.isEmpty
        ? (widget.book.content.isNotEmpty && widget.chunk.endOffset > widget.chunk.startOffset
            ? widget.book.content.substring(
                widget.chunk.startOffset.clamp(0, widget.book.content.length),
                widget.chunk.endOffset.clamp(0, widget.book.content.length))
            : 'No content for this chapter.')
        : widget.chunk.subChunks.map((s) => s.content).join('\n\n');
    final allText = _cleanText(rawText);

    // Re-paginate if text or font size changed
    if (_cachedText != allText || _lastFontSize != _fontSize) {
      _cachedText = allText;
      _lastFontSize = _fontSize;
      final charsPerPage = _fontSize < 18 ? 2200 : 1700;
      _pages = _paginateText(allText, charsPerPage);
      _currentPage = _currentPage.clamp(0, _pages.length - 1);
    }

    final totalPages = _pages.length;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: totalPages,
          itemBuilder: (context, index) {
            final pageText = _pages[index];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key idea banner on first page only
                  if (index == 0 && widget.chunk.keyIdea.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [_theme.accent, const Color(0xFF4F46E5)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(widget.chunk.keyIdea,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SelectableText.rich(
                    _buildStyledText(pageText),
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.8,
                      color: _theme.text,
                      fontFamily: 'Georgia',
                      letterSpacing: 0.1,
                    ),
                    onSelectionChanged: (selection, cause) {
                      if (!selection.isCollapsed) {
                        final end = selection.end.clamp(0, pageText.length);
                        final start = selection.start.clamp(0, end);
                        final text = pageText.substring(start, end).trim();
                        if (text.length > 3 && text != _selectedText) {
                          setState(() => _selectedText = text);
                        }
                        if (cause == SelectionChangedCause.longPress) {
                          _onTextSelected(text);
                        }
                      } else {
                        if (_selectedText != null) {
                          setState(() => _selectedText = null);
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        // Page counter + swipe hint
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentPage > 0)
                Icon(Icons.chevron_left_rounded,
                    size: 16,
                    color: _theme.text.withValues(alpha: 0.25)),
              const SizedBox(width: 2),
              Text(
                '${_currentPage + 1} / $totalPages',
                style: TextStyle(
                    fontSize: 12,
                    color: _theme.text.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 2),
              if (_currentPage < totalPages - 1)
                Icon(Icons.chevron_right_rounded,
                    size: 16,
                    color: _theme.text.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a TextSpan tree with yellow-background spans for all saved highlights.
  TextSpan _buildStyledText(String text) {
    if (_loadedHighlights.isEmpty) {
      return TextSpan(text: text);
    }

    // Find all [start, end) ranges for each highlight phrase in the text
    final ranges = <(int, int)>[];
    for (final hl in _loadedHighlights) {
      if (hl.length < 3) continue;
      int start = 0;
      while (start < text.length) {
        final idx = text.indexOf(hl, start);
        if (idx == -1) break;
        ranges.add((idx, idx + hl.length));
        start = idx + hl.length;
      }
    }

    if (ranges.isEmpty) return TextSpan(text: text);

    // Sort and merge overlapping ranges
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final r in ranges) {
      if (merged.isEmpty || r.$1 > merged.last.$2) {
        merged.add(r);
      } else {
        merged[merged.length - 1] =
            (merged.last.$1, max(merged.last.$2, r.$2));
      }
    }

    // Build span list: plain text → highlighted text → plain text → …
    const highlightBg = Color(0xFFFFEC99);
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final (start, end) in merged) {
      final clampedEnd = end.clamp(0, text.length);
      final clampedStart = start.clamp(0, text.length);
      if (clampedStart > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, clampedStart)));
      }
      if (clampedEnd > clampedStart) {
        spans.add(TextSpan(
          text: text.substring(clampedStart, clampedEnd),
          style: const TextStyle(backgroundColor: highlightBg),
        ));
      }
      cursor = clampedEnd;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(children: spans);
  }

  void _onTextSelected(String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _theme.text)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text.length > 200 ? '${text.substring(0, 200)}…' : text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF3B2A1A), fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _saveHighlight(text);
                    },
                    icon: const Icon(Icons.highlight_rounded, size: 18),
                    label: const Text('Highlight'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openAIChat(prefilledQuestion:
                          'Can you help me think about this passage: "$text"');
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Ask AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _theme.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHighlight(String text) async {
    setState(() {
      _sessionHighlights.add(text);
      if (!_loadedHighlights.contains(text)) {
        _loadedHighlights.add(text); // Show immediately in text
      }
    });
    final user = ref.read(authUserProvider);
    final db = ref.read(databaseServiceProvider);
    if (user != null) {
      await db.saveHighlight(
        userId: user.id,
        bookId: widget.book.id,
        chunkId: widget.chunk.id,
        text: text,
        positionPct: _scrollCompletion,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Highlight saved ✓'),
        backgroundColor: _theme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _highlightSelected() {
    if (_selectedText != null && _selectedText!.isNotEmpty) {
      _saveHighlight(_selectedText!);
      setState(() => _selectedText = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text('Long-press words to select text, then tap Highlight'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _addBookmark() {
    final pct = (_scrollCompletion * 100).round();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bookmark saved at $pct% ✓'),
      backgroundColor: const Color(0xFF0EA5E9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _openAIChat({String? prefilledQuestion}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdaptiveAIChatSheet(
        book: widget.book,
        chunk: widget.chunk,
        theme: _theme,
        initialMessage: prefilledQuestion,
        onQuestionAsked: (q) => setState(() => _sessionAiQuestions.add(q)),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: _theme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          _iconBtn(Icons.chat_bubble_outline_rounded, 'Ask AI', _theme.accent,
              () => _openAIChat()),
          const SizedBox(width: 8),
          _highlightBtn(),
          const SizedBox(width: 8),
          _iconBtn(Icons.bookmark_border_rounded, 'Bookmark',
              const Color(0xFF0EA5E9), _addBookmark),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _completeSession,
              icon: Icon(_isSaving ? Icons.hourglass_empty : Icons.check_rounded, size: 18),
              label: Text(_isSaving ? 'Saving…' : 'Complete Day'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightBtn() {
    const color = Color(0xFFF59E0B);
    final hasSelection = _selectedText != null;
    return InkWell(
      onTap: _highlightSelected,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasSelection
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: hasSelection
              ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.highlight_rounded, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              hasSelection ? 'Save!' : 'Highlight',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    hasSelection ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Adaptive AI Chat Sheet ────────────────────────────────────────────────────
// Uses AiProviderService (Claude → Gemini → OpenAI).
// Builds full adaptive RAG context before every exchange.

class _AdaptiveAIChatSheet extends ConsumerStatefulWidget {
  final Book book;
  final BookChunk chunk;
  final ReadingTheme theme;
  final String? initialMessage;
  final void Function(String question) onQuestionAsked;

  const _AdaptiveAIChatSheet({
    required this.book,
    required this.chunk,
    required this.theme,
    required this.onQuestionAsked,
    this.initialMessage,
  });

  @override
  ConsumerState<_AdaptiveAIChatSheet> createState() =>
      _AdaptiveAIChatSheetState();
}

class _AdaptiveAIChatSheetState extends ConsumerState<_AdaptiveAIChatSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _aiService = AiProviderService();
  final List<ChatMessage> _history = [];
  final List<_ChatBubbleData> _bubbles = [];
  bool _loading = false;
  AiProvider _lastProvider = AiProvider.claude;
  AdaptiveContext? _cachedContext;

  @override
  void initState() {
    super.initState();
    _loadContextThenOpen();
  }

  Future<void> _loadContextThenOpen() async {
    final user = ref.read(authUserProvider);
    final db = ref.read(databaseServiceProvider);
    if (user != null) {
      final rag = AdaptiveRagService(db);
      _cachedContext = await rag.buildContext(
          userId: user.id, book: widget.book, chunk: widget.chunk);
    }

    if (widget.initialMessage != null) {
      _ctrl.text = widget.initialMessage!;
      await _send();
    } else {
      await _sendOpener();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _callbackContext() {
    final completed = widget.book.chunks
        .where((c) => c.completed && c.id != widget.chunk.id)
        .toList();
    if (completed.isEmpty) return '';
    return completed.map((c) => '• Day ${c.dayNumber}: ${c.keyIdea.isNotEmpty ? c.keyIdea : c.episodeTitle}').join('\n');
  }

  Future<void> _sendOpener() async {
    setState(() => _loading = true);
    final user = ref.read(authUserProvider);
    try {
      final result = await _aiService.socraticChat(
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        currentDay: widget.chunk.dayNumber,
        totalDays: widget.book.chunks.length,
        userName: user?.displayName ?? 'Reader',
        history: [
          ChatMessage(
              role: 'user',
              content: "I just finished reading Day ${widget.chunk.dayNumber}: ${widget.chunk.episodeTitle}. What should I reflect on?")
        ],
        adaptiveContext: _cachedContext?.toPromptString(),
        callbackContext: _callbackContext(),
      );
      if (mounted) {
        setState(() {
          _bubbles.add(_ChatBubbleData(text: result.reply, isUser: false, provider: result.providerBadge));
          _history.add(ChatMessage(role: 'assistant', content: result.reply));
          _lastProvider = result.provider;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();

    final user = ref.read(authUserProvider);
    final db = ref.read(databaseServiceProvider);

    // Track question
    widget.onQuestionAsked(text);

    final userMsg = ChatMessage(role: 'user', content: text);
    setState(() {
      _bubbles.add(_ChatBubbleData(text: text, isUser: true));
      _history.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    try {
      final result = await _aiService.socraticChat(
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        currentDay: widget.chunk.dayNumber,
        totalDays: widget.book.chunks.length,
        userName: user?.displayName ?? 'Reader',
        history: _history,
        adaptiveContext: _cachedContext?.toPromptString(),
        callbackContext: _callbackContext(),
      );

      // Save interaction to DB
      if (user != null) {
        final tags = _aiService.extractTopicTags(text);
        await db.saveAiInteraction(
          userId: user.id,
          bookId: widget.book.id,
          chunkId: widget.chunk.id,
          question: text,
          response: result.reply,
          topicTags: tags,
          provider: result.provider.name,
        );
      }

      if (mounted) {
        setState(() {
          _bubbles.add(_ChatBubbleData(text: result.reply, isUser: false, provider: result.providerBadge));
          _history.add(ChatMessage(role: 'assistant', content: result.reply));
          _lastProvider = result.provider;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bubbles.add(_ChatBubbleData(
              text: 'Connection issue. Please try again.',
              isUser: false));
          _loading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome, color: t.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Socratic Companion',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: t.text)),
                        Text('Day ${widget.chunk.dayNumber} · ${widget.book.title}',
                            style: TextStyle(fontSize: 11, color: t.text.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  // Provider badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _lastProvider == AiProvider.claude ? '⚡ Claude'
                          : _lastProvider == AiProvider.gemini ? '♊ Gemini'
                          : _lastProvider == AiProvider.openai ? '🤖 GPT-4o'
                          : '···',
                      style: TextStyle(fontSize: 10, color: t.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Context indicator
            if (_cachedContext != null && !_cachedContext!.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: const Color(0xFF059669).withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text('Adaptive context loaded — highlights, pace & AI history active',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _bubbles.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _bubbles.length) return _TypingBubble(theme: t);
                  return _BubbleWidget(data: _bubbles[i], theme: t);
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
              decoration: BoxDecoration(
                color: t.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: TextStyle(color: t.text, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Ask about what you just read…',
                        hintStyle: TextStyle(color: t.text.withValues(alpha: 0.4), fontSize: 14),
                        filled: true,
                        fillColor: t.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
                      child: Icon(_loading ? Icons.hourglass_empty : Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubbleData {
  final String text;
  final bool isUser;
  final String? provider;
  const _ChatBubbleData({required this.text, required this.isUser, this.provider});
}

class _BubbleWidget extends StatelessWidget {
  final _ChatBubbleData data;
  final ReadingTheme theme;
  const _BubbleWidget({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: data.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: data.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: data.isUser ? theme.accent : theme.bg,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: data.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !data.isUser ? const Radius.circular(4) : null,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(data.text,
                  style: TextStyle(fontSize: 14, height: 1.5,
                      color: data.isUser ? Colors.white : theme.text)),
            ),
            if (!data.isUser && data.provider != null)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4),
                child: Text(data.provider!,
                    style: TextStyle(fontSize: 9, color: Colors.grey[400])),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final ReadingTheme theme;
  const _TypingBubble({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(theme, 0), const SizedBox(width: 4),
          _dot(theme, 1), const SizedBox(width: 4),
          _dot(theme, 2),
        ]),
      ),
    );
  }

  Widget _dot(ReadingTheme t, int i) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: t.accent.withValues(alpha: 0.5), shape: BoxShape.circle));
}

// ─── Session Complete Dialog ──────────────────────────────────────────────────

class _SessionCompleteDialog extends StatelessWidget {
  final BookChunk chunk;
  final int elapsedMinutes;
  final int wpm;
  final int xpEarned;
  final int highlights;
  final int aiQuestions;
  final double scrollCompletion;
  final int? newLevel;
  final List<String> newAchievements;
  final VoidCallback onDone;
  final VoidCallback onContinue;

  const _SessionCompleteDialog({
    required this.chunk, required this.elapsedMinutes, required this.wpm,
    required this.xpEarned, required this.highlights, required this.aiQuestions,
    required this.scrollCompletion, required this.newAchievements,
    required this.onDone, required this.onContinue, this.newLevel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF6B21A8).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Day Complete! 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
            const SizedBox(height: 6),
            Text(chunk.episodeTitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _stat('⏱', '$elapsedMinutes min', 'Time'),
              _div(), _stat('⚡', wpm > 0 ? '$wpm wpm' : '—', 'Speed'),
              _div(), _stat('⭐', '+$xpEarned', 'XP'),
            ]),
            if (highlights > 0 || aiQuestions > 0) ...[
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (highlights > 0) _chip(Icons.highlight_rounded, '$highlights highlights', const Color(0xFFF59E0B)),
                if (highlights > 0 && aiQuestions > 0) const SizedBox(width: 8),
                if (aiQuestions > 0) _chip(Icons.chat_bubble_outline_rounded, '$aiQuestions questions', const Color(0xFF6B21A8)),
              ]),
            ],
            if (scrollCompletion > 0) ...[
              const SizedBox(height: 12),
              Row(children: [
                Text('Read:', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: scrollCompletion, minHeight: 6,
                      backgroundColor: Colors.grey[100],
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF059669)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(scrollCompletion * 100).round()}%',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF059669))),
              ]),
            ],
            if (newLevel != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🌟 ', style: TextStyle(fontSize: 18)),
                  Text('Level $newLevel!', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                ]),
              ),
            ],
            if (newAchievements.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...newAchievements.take(2).map((id) {
                final def = kAllAchievements.firstWhere(
                  (a) => a.id == id,
                  orElse: () => const AchievementDef(id: '', emoji: '🏅', title: 'Achievement', description: '', xpReward: 0, category: ''),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Text(def.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Achievement Unlocked!', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text(def.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8))),
                      ]),
                    ]),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: onContinue, child: Text('Keep Reading', style: TextStyle(color: Colors.grey[600]))),
        ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B21A8), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _stat(String emoji, String value, String label) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
  ]);

  Widget _div() => Container(width: 1, height: 40, color: Colors.grey[200]);

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14), const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    ]),
  );
}
