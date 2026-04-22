import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart' show AppLocalizationsX;
import '../curriculum/curriculum_map_screen.dart';
import '../library/books_screen.dart';
import '../insights/insights_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/curriculum_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final curriculum = ref.watch(curriculumProvider).value;
    final topic = curriculum?.topic;
    final l = context.l10n;

    final screens = <Widget>[
      const CurriculumMapScreen(),
      BooksScreen(recommendedTopic: topic),
      const InsightsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded),
            label: l.navLearn,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: l.navBooks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.hub_outlined),
            selectedIcon: const Icon(Icons.hub_rounded),
            label: l.navInsights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l.navProfile,
          ),
        ],
      ),
    );
  }
}
