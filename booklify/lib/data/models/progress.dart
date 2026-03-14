class Progress {
  final String id;
  final String userId;
  final String bookId;
  final int currentDay;
  final int totalDays;
  final List<String> completedDays;
  final int xp;
  final int level;
  final DateTime? lastSessionDate;
  final int streakDays;
  final DateTime? startDate;
  final DateTime? completedDate;

  Progress({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.currentDay,
    required this.totalDays,
    this.completedDays = const [],
    this.xp = 0,
    this.level = 1,
    this.lastSessionDate,
    this.streakDays = 0,
    this.startDate,
    this.completedDate,
  });

  double get progressPercent => totalDays > 0 ? currentDay / totalDays : 0;

  int get xpToNextLevel => level * 100;

  double get levelProgress => (xp % 100) / 100;

  bool get isCompleted => currentDay >= totalDays;

  Progress copyWith({
    String? id,
    String? userId,
    String? bookId,
    int? currentDay,
    int? totalDays,
    List<String>? completedDays,
    int? xp,
    int? level,
    DateTime? lastSessionDate,
    int? streakDays,
    DateTime? startDate,
    DateTime? completedDate,
  }) {
    return Progress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      currentDay: currentDay ?? this.currentDay,
      totalDays: totalDays ?? this.totalDays,
      completedDays: completedDays ?? this.completedDays,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      streakDays: streakDays ?? this.streakDays,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Progress addXP(int amount) {
    final newXP = xp + amount;
    final newLevel = (newXP ~/ 100) + 1;
    return copyWith(
      xp: newXP,
      level: newLevel,
    );
  }

  Progress completeDay() {
    final today = DateTime.now();
    final newCompletedDays = [...completedDays, today.toIso8601String().split('T')[0]];
    final newDay = currentDay + 1;

    return copyWith(
      completedDays: newCompletedDays,
      currentDay: newDay.clamp(1, totalDays),
      lastSessionDate: today,
      streakDays: streakDays + 1,
    ).addXP(50); // 50 XP for completing a day
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'currentDay': currentDay,
      'totalDays': totalDays,
      'completedDays': completedDays,
      'xp': xp,
      'level': level,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'streakDays': streakDays,
      'startDate': startDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      currentDay: json['currentDay'] as int,
      totalDays: json['totalDays'] as int,
      completedDays: (json['completedDays'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      lastSessionDate: json['lastSessionDate'] != null
          ? DateTime.parse(json['lastSessionDate'] as String)
          : null,
      streakDays: json['streakDays'] as int? ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
    );
  }
}