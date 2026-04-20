import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../../data/services/claude_service.dart';
import '../../providers/auth_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final Book book;
  final int currentPage;
  final BookChunk? currentChunk;

  const AIChatScreen({
    super.key,
    required this.book,
    this.currentPage = 0,
    this.currentChunk,
  });

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_UIMessage> _messages = [];
  final ClaudeService _claude = ClaudeService();

  bool _isLoading = false;

  // ── RAG context builders ───────────────────────────────────────────────────

  /// Extracts the most relevant passage from the current chunk's text.
  /// For a Flutter/local-only app this is "text-based RAG": we take the
  /// current chunk's full content (the actual book passage the user is
  /// reading) and inject it so Claude can quote from it.
  String _buildRagContext() {
    final chunk = widget.currentChunk;
    if (chunk == null) return '';

    // Primary: current chunk text (what the user is reading right now)
    final parts = <String>[];

    if (chunk.subChunks.isNotEmpty) {
      for (final sub in chunk.subChunks) {
        if (sub.content.trim().isNotEmpty) {
          parts.add(sub.content.trim());
        }
      }
    }

    // Fallback: extract slice from full book content by offsets
    if (parts.isEmpty && widget.book.content.isNotEmpty) {
      final start = chunk.startOffset.clamp(0, widget.book.content.length);
      final end = chunk.endOffset.clamp(start, widget.book.content.length);
      if (end > start) {
        parts.add(widget.book.content.substring(start, end));
      }
    }

    if (parts.isEmpty) return '';

    // Truncate to ~2000 chars to stay within context budget
    final raw = parts.join('\n\n');
    return raw.length > 2000 ? '${raw.substring(0, 2000)}…' : raw;
  }

  /// Cross-episode callback retrieval: collects key ideas from all
  /// previously completed chunks so the companion can prompt synthesis
  /// between current and prior reading.
  String _buildCallbackContext() {
    final completedChunks = widget.book.chunks
        .where((c) => c.completed && c.id != widget.currentChunk?.id)
        .toList();

    if (completedChunks.isEmpty) return '';

    final lines = completedChunks.map((c) {
      final idea = c.keyIdea.isNotEmpty ? c.keyIdea : c.episodeTitle;
      return '• Day ${c.dayNumber} — $idea';
    }).join('\n');

    return 'Previously completed episodes:\n$lines';
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _sendOpeningQuestion();
  }

  /// The companion always opens with a Socratic question — never waits
  /// for the user to speak first.
  Future<void> _sendOpeningQuestion() async {
    setState(() => _isLoading = true);

    final userName = ref.read(authProvider).user?.displayName ?? 'Reader';

    try {
      final response = await _claude.socraticChat(
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        currentPage: widget.currentPage,
        totalPages: widget.book.totalPages,
        userName: userName,
        history: const [],
        ragContext: _buildRagContext(),
        callbackContext: _buildCallbackContext(),
      );

      if (mounted) {
        setState(() {
          _messages.add(_UIMessage(content: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_UIMessage(
            content: "Let's explore \"${widget.currentChunk?.episodeTitle ?? widget.book.title}\" together. What struck you most from what you just read?",
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();

    setState(() {
      _messages.add(_UIMessage(content: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final userName = ref.read(authProvider).user?.displayName ?? 'Reader';

    // Build full history for Claude (excluding the opening question so
    // it doesn't double-count the system framing)
    final history = _messages.map((m) => ChatMessage(
      role: m.isUser ? 'user' : 'assistant',
      content: m.content,
    )).toList();

    try {
      final response = await _claude.socraticChat(
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        currentPage: widget.currentPage,
        totalPages: widget.book.totalPages,
        userName: userName,
        history: history,
        ragContext: _buildRagContext(),
        callbackContext: _buildCallbackContext(),
      );

      if (mounted) {
        setState(() {
          _messages.add(_UIMessage(content: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_UIMessage(
            content: 'Something went wrong. Please try again.',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chunkTitle = widget.currentChunk?.episodeTitle ?? widget.book.title;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Socratic Companion',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              chunkTitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildContextBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(_messages[i]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildContextBanner() {
    final completedCount = widget.book.chunks.where((c) => c.completed).length;
    final totalChunks = widget.book.chunks.length;
    final hasCallbacks = completedCount > 0;

    return Container(
      color: const Color(0xFF4F46E5),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _pill('📖 Page ${widget.currentPage}'),
          const SizedBox(width: 8),
          if (totalChunks > 0)
            _pill('$completedCount/$totalChunks sessions'),
          const SizedBox(width: 8),
          if (hasCallbacks)
            _pill('🔗 Callbacks active'),
        ],
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  Widget _buildBubble(_UIMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🦉', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF4F46E5) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1F1F3D),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 18, color: Color(0xFF4F46E5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🦉', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isLoading,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts…',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.grey[300]
                      : const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    final ragAvailable = _buildRagContext().isNotEmpty;
    final callbackAvailable = _buildCallbackContext().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About Your Companion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('📚', 'Book', '${widget.book.title} by ${widget.book.author}'),
            _infoRow('📖', 'Reading', 'Page ${widget.currentPage} of ${widget.book.totalPages}'),
            _infoRow(
              ragAvailable ? '✅' : '⚪',
              'RAG context',
              ragAvailable ? 'Current passage injected' : 'No text available',
            ),
            _infoRow(
              callbackAvailable ? '✅' : '⚪',
              'Cross-episode',
              callbackAvailable ? 'Prior episodes linked' : 'First episode',
            ),
            const SizedBox(height: 12),
            Text(
              'The companion poses Socratic questions grounded in what you\'re reading. '
              'It supports English, Russian, and Uzbek — just write in your language.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Typing animation ──────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = (i / 3);
            final t = ((_ctrl.value + offset) % 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _UIMessage {
  final String content;
  final bool isUser;
  _UIMessage({required this.content, required this.isUser});
}
