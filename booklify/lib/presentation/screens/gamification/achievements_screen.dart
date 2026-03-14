import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Achievements')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text('Achievements Coming Soon', style: TextStyle(fontSize: 18)),
            Text('Your badges and milestones will appear here'),
          ],
        ),
      ),
    );
  }
}
