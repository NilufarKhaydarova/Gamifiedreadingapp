import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Dashboard Coming Soon', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Your reading progress and stats will appear here'),
          ],
        ),
      ),
    );
  }
}
