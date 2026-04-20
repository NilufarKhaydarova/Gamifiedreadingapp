import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary (Duolingo-style vivid green) ─────────────────────────────────
  static const Color primary = Color(0xFF58CC02);
  static const Color primaryDark = Color(0xFF45A301);
  static const Color primaryLight = Color(0xFF89E219);
  static const Color primarySurface = Color(0xFFD7FFB8);

  // ─── Forest greens ────────────────────────────────────────────────────────
  static const Color forestDark = Color(0xFF1A472A);
  static const Color forestMid = Color(0xFF2D6A4F);
  static const Color forestLight = Color(0xFF52B788);

  // ─── Backgrounds ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF0F4F8);

  // ─── Gamification ────────────────────────────────────────────────────────
  static const Color xpGold = Color(0xFFFFD900);
  static const Color xpGoldDark = Color(0xFFE5A100);
  static const Color streakOrange = Color(0xFFFF9600);
  static const Color hearts = Color(0xFFFF4B4B);
  static const Color gems = Color(0xFF1CB0F6);
  static const Color gemsDark = Color(0xFF0095D9);

  // ─── Level colors (one per curriculum level) ──────────────────────────────
  static const Color level1 = Color(0xFF58CC02); // Green
  static const Color level2 = Color(0xFF1CB0F6); // Sky blue
  static const Color level3 = Color(0xFFCE82FF); // Purple
  static const Color level4 = Color(0xFFFF9600); // Orange
  static const Color level5 = Color(0xFFFF4B4B); // Red/coral

  static const List<Color> levelColors = [
    level1, level2, level3, level4, level5,
  ];

  /// Get level color by 1-based level number (cycles for >5 levels)
  static Color forLevel(int levelNumber) {
    return levelColors[(levelNumber - 1) % levelColors.length];
  }

  // ─── Lesson step types ────────────────────────────────────────────────────
  static const Color stepRead = Color(0xFF58CC02);
  static const Color stepQuiz = Color(0xFF1CB0F6);
  static const Color stepChat = Color(0xFFCE82FF);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3C3C3C);
  static const Color textSecondary = Color(0xFF777777);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ─── Borders & dividers ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderFocus = Color(0xFF58CC02);
  static const Color divider = Color(0xFFF0F0F0);

  // ─── Feedback ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF58CC02);
  static const Color successLight = Color(0xFFD7FFB8);
  static const Color error = Color(0xFFFF4B4B);
  static const Color errorLight = Color(0xFFFFE0E0);
  static const Color warning = Color(0xFFFF9600);
  static const Color warningLight = Color(0xFFFFF3E0);

  // ─── Locked / disabled ───────────────────────────────────────────────────
  static const Color locked = Color(0xFFCECECE);
  static const Color lockedDark = Color(0xFFAFAFAF);

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static const Color shadowColor = Color(0x1A000000);

  // Legacy aliases (keep for compatibility with old screens)
  static const Color primaryLight2 = Color(0xFF89E219);
  static const Color secondary = Color(0xFFFF9600);
  static const Color onBackground = Color(0xFF3C3C3C);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Color(0xFF3C3C3C);
  static const Color xpGold2 = xpGold;
  static const Color streakFire = streakOrange;
  static const Color witherGray = locked;
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color cloudyGray = Color(0xFFB0BEC5);
  static const Color stormyDark = Color(0xFF546E7A);
  static const Color readingSurface = Color(0xFFFFFEF9);
  static const Color textSecondary2 = textSecondary;
  static const Color achievementBronze = Color(0xFFCD7F32);
  static const Color achievementSilver = Color(0xFFC0C0C0);
  static const Color achievementGold = Color(0xFFFFD700);
  static const Color difficultyLight = Color(0xFF4ADE80);
  static const Color difficultyModerate = Color(0xFFFBBF24);
  static const Color difficultyDense = Color(0xFFF87171);
}
