import 'package:booklify/data/models/achievement.dart';
import 'package:booklify/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Achievement', () {
    test('unlock() sets unlockedAt and isUnlocked', () {
      final a = Achievements.all.first;
      expect(a.isUnlocked, isFalse);
      expect(a.unlock().isUnlocked, isTrue);
    });

    test('JSON round-trip and unknown category fallback', () {
      final a = Achievements.all[1].unlock();
      expect(Achievement.fromJson(a.toJson()).toJson(), a.toJson());
      final json = a.toJson()..['category'] = 'nope';
      expect(Achievement.fromJson(json).category, AchievementCategory.streak);
    });

    test('predefined achievements have unique ids', () {
      final ids = Achievements.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('User', () {
    test('JSON round-trip', () {
      final u = User(
        id: 'u1',
        email: 'a@b.c',
        displayName: 'Ann',
        age: 30,
        favoriteGenres: ['Fiction'],
        createdAt: DateTime(2026, 1, 1),
        onboardingComplete: true,
        preferredLanguage: 'uz',
      );
      expect(User.fromJson(u.toJson()).toJson(), u.toJson());
    });
  });
}
