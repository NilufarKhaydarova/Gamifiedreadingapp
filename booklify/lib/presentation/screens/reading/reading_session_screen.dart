import 'package:flutter/material.dart';

class ReadingSessionScreen extends StatefulWidget {
  final String bookId;
  final String chunkId;

  const ReadingSessionScreen({
    super.key,
    required this.bookId,
    required this.chunkId,
  });

  @override
  State<ReadingSessionScreen> createState() => _ReadingSessionScreenState();
}

class _ReadingSessionScreenState extends State<ReadingSessionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reading Session')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Reading Session Coming Soon', style: TextStyle(fontSize: 18)),
            Text('Book: ${widget.bookId}, Chunk: ${widget.chunkId}'),
          ],
        ),
      ),
    );
  }
}
