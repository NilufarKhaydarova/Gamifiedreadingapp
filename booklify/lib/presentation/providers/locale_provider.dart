import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Supported locales ─────────────────────────────────────────────────────────

class AppLocale {
  final Locale locale;
  final String flag;
  final String name;

  const AppLocale({required this.locale, required this.flag, required this.name});
}

const supportedAppLocales = [
  AppLocale(locale: Locale('en'), flag: '🇺🇸', name: 'English'),
  AppLocale(locale: Locale('ru'), flag: '🇷🇺', name: 'Русский'),
  AppLocale(locale: Locale('uz'), flag: '🇺🇿', name: "O'zbekcha"),
];

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    // Start with English; load persisted value asynchronously
    _load();
    return const Locale('en');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
