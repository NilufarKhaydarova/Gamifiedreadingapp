import 'package:flutter/material.dart';
import '../../../data/models/book.dart';
import '../../../data/services/claude_service.dart';
import '../../../core/constants/api_keys.dart';

class AIChatScreen extends StatefulWidget {
  final Book book;
  final int currentPage;
  final BookChunk currentChunk;

  const AIChatScreen({
    super.key,
    required this.book,
    required this.currentPage,
    required this.currentChunk,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_UIMessage> _messages = [];
  late final ClaudeService _claude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _claude = ClaudeService();
    // Open with a Socratic prompt
    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcome());
  }

  void _addWelcome() {
    if (!ApiKeys.hasClaudeKey) {
      setState(() {
        _messages.add(_UIMessage(
          content:
              '⚠️ Add your Anthropic API key to assets/.env to enable AI chat.\n\n'
              'Set ANTHROPIC_API_KEY=sk-ant-...',
          isUser: false,
          isWarning: true,
        ));
      });
      return;
    }
    setState(() {
      _messages.add(_UIMessage(
        content:
            "I'm your Socratic reading companion for *${widget.book.title}*. "
            "You're on page ${widget.currentPage} — what's on your mind so far? "
            "What surprised you, confused you, or made you think?",
        isUser: false,
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

    try {
      // Build history (skip welcome message)
      final history = _messages
          .where((m) => !m.isWarning)
          .take(_messages.length - 1) // exclude the message just added
          .map((m) => ChatMessage(
                role: m.isUser ? 'user' : 'assistant',
                content: m.content,
              ))
          .toList();

      // Add the new user message
      history.add(ChatMessage(role: 'user', content: text));

      final reply = await _claude.socraticChat(
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        currentPage: widget.currentPage,
        totalPages: widget.book.totalPages,
        userName: 'Reader',
        history: history,
      );

      if (mounted) {
        setState(() {
          _messages.add(_UIMessage(content: reply, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_UIMessage(
            content: 'Could not reach Claude. Check your API key and connection.',
            isUser: false,
            isWarning: true,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Reading Companion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('claude-sonnet-4-5 · page ${widget.currentPage}',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.deepPurple[300]),
            const SizedBox(height: 16),
            Text(
              '"${widget.book.title}"',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _chip("What's the main theme?"),
                _chip("Explain this character"),
                _chip("Why did this happen?"),
                _chip("What should I notice?"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 13)),
      onPressed: () {
        _controller.text = text;
        _sendMessage();
      },
      backgroundColor: Colors.deepPurple[50],
    );
  }

  Widget _buildBubble(_UIMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple[700],
              child: const Text('✦',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.deepPurple[600]
                    : msg.isWarning
                        ? Colors.orange[50]
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : msg.isWarning
                          ? Colors.orange[900]
                          : Colors.black87,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[400],
              child: const Icon(Icons.person, color: Colors.white, size: 18),
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
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.deepPurple[700],
            child: const Text('✦',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.deepPurple[400],
            shape: BoxShape.circle,
          ),
        ),
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
                decoration: InputDecoration(
                  hintText: 'Ask anything about the book…',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.deepPurple[400]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              onPressed: _isLoading ? null : _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI Reading Companion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Model', 'Claude Sonnet 4.5'),
            _infoRow('Book', widget.book.title),
            _infoRow('Author', widget.book.author),
            _infoRow('Page', '${widget.currentPage} / ${widget.book.totalPages}'),
            const SizedBox(height: 12),
            Text(
              'Uses Socratic method — guides you to deeper understanding through questions rather than giving answers.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
              child: Text(value,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        ],
      ),
    );
  }
}

class _UIMessage {
  final String content;
  final bool isUser;
  final bool isWarning;
  _UIMessage({required this.content, required this.isUser, this.isWarning = false});
}
