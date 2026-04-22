import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/main/main_screen.dart';

export 'l10n/app_localizations.dart';

/// Convenience extension — use `context.l10n.someKey` anywhere in the widget tree.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class BooklifyApp extends ConsumerWidget {
  const BooklifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Booklify',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,

      // ── Localization ──────────────────────────────────────────────────────
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('uz'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

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
