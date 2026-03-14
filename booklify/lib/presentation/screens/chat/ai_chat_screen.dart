import 'package:flutter/material.dart';

class AIChatScreen extends StatefulWidget {
  final String bookId;

  const AIChatScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Reading Companion')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('Ask about the book you\'re reading!'),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ListTile(
                        title: Text(message.content),
                        trailing: Icon(
                          message.isUser ? Icons.person : Icons.smart_toy,
                          color: message.isUser ? Colors.blue : Colors.green,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about the book...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() {
                        _messages.add(ChatMessage(
                          content: _controller.text,
                          isUser: true,
                        ));
                        _controller.clear();
                      });

                      // Simulate AI response
                      Future.delayed(Duration(seconds: 1), () {
                        setState(() {
                          _messages.add(ChatMessage(
                            content: 'That\'s a great question! What do you think about this theme?',
                            isUser: false,
                          ));
                        });
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({required this.content, required this.isUser});
}
