import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/library/library_screen.dart';
import 'presentation/screens/reading/reading_session_screen.dart';
import 'presentation/screens/garden/reading_garden_screen.dart';
import 'presentation/screens/gamification/achievements_screen.dart';
import 'presentation/screens/chat/ai_chat_screen.dart';

class BooklifyApp extends StatelessWidget {
  const BooklifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Booklify - Grow Your Mind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }

  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/garden',
        name: 'garden',
        builder: (context, state) => const ReadingGardenScreen(),
      ),
      GoRoute(
        path: '/reading',
        name: 'reading',
        builder: (context, state) {
          final bookId = state.uri.queryParameters['bookId'];
          final chunkId = state.uri.queryParameters['chunkId'];
          return ReadingSessionScreen(
            bookId: bookId ?? '',
            chunkId: chunkId ?? '',
          );
        },
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final bookId = state.uri.queryParameters['bookId'];
          return AIChatScreen(bookId: bookId ?? '');
        },
      ),
    ],
  );
}