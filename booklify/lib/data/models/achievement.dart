class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final AchievementCategory category;
  final int? targetValue;
  final int? xpReward;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.category,
    this.targetValue,
    this.xpReward,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    AchievementCategory? category,
    int? targetValue,
    int? xpReward,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      xpReward: xpReward ?? this.xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Achievement unlock() {
    return copyWith(unlockedAt: DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'category': category.name,
      'targetValue': targetValue,
      'xpReward': xpReward,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.streak,
      ),
      targetValue: json['targetValue'] as int?,
      xpReward: json['xpReward'] as int?,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

enum AchievementCategory {
  streak,
  readingSpeed,
  comprehension,
  social,
  level
}

// Predefined achievements
class Achievements {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_leaf',
      title: 'First Leaf',
      description: 'Complete your first reading day',
      iconUrl: 'assets/icons/achievements/first_leaf.png',
      category: AchievementCategory.streak,
      targetValue: 1,
      xpReward: 25,
    ),
    Achievement(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Maintain a 7-day reading streak',
      iconUrl: 'assets/icons/achievements/week_warrior.png',
      category: AchievementCategory.streak,
      targetValue: 7,
      xpReward: 100,
    ),
    Achievement(
      id: 'kindled',
      title: 'Kindled',
      description: 'Maintain a 14-day reading streak',
      iconUrl: 'assets/icons/achievements/kindled.png',
      category: AchievementCategory.streak,
      targetValue: 14,
      xpReward: 200,
    ),
    Achievement(
      id: 'electrified',
      title: 'Electrified',
      description: 'Maintain a 30-day reading streak',
      iconUrl: 'assets/icons/achievements/electrified.png',
      category: AchievementCategory.streak,
      targetValue: 30,
      xpReward: 500,
    ),
    Achievement(
      id: 'in_flow',
      title: 'In Flow',
      description: 'Maintain a 60-day reading streak',
      iconUrl: 'assets/icons/achievements/in_flow.png',
      category: AchievementCategory.streak,
      targetValue: 60,
      xpReward: 1000,
    ),
    Achievement(
      id: 'speed_reader',
      title: 'Speed Reader',
      description: 'Read 80+ pages per hour',
      iconUrl: 'assets/icons/achievements/speed_reader.png',
      category: AchievementCategory.readingSpeed,
      targetValue: 80,
      xpReward: 150,
    ),
    Achievement(
      id: 'quick_study',
      title: 'Quick Study',
      description: 'Read 50+ pages per hour',
      iconUrl: 'assets/icons/achievements/quick_study.png',
      category: AchievementCategory.readingSpeed,
      targetValue: 50,
      xpReward: 75,
    ),
  ];
}