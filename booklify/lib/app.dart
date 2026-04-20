import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/main/main_screen.dart';

class BooklifyApp extends StatelessWidget {
  const BooklifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booklify',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);
    return switch (authStatus) {
      AuthStatus.initial || AuthStatus.loading =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.authenticated => const MainScreen(),
      AuthStatus.unauthenticated || AuthStatus.error => const OnboardingScreen(),
    };
  }
}
