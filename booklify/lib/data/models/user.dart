class User {
  final String id;
  final String email;
  final String? displayName;
  final int? age;
  final String? education;
  final int? booksPerYear;
  final List<String>? favoriteGenres;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool? onboardingComplete;
  final String? preferredLanguage;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.age,
    this.education,
    this.booksPerYear,
    this.favoriteGenres,
    this.createdAt,
    this.lastLoginAt,
    this.onboardingComplete,
    this.preferredLanguage,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    int? age,
    String? education,
    int? booksPerYear,
    List<String>? favoriteGenres,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? onboardingComplete,
    String? preferredLanguage,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      education: education ?? this.education,
      booksPerYear: booksPerYear ?? this.booksPerYear,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'age': age,
      'education': education,
      'booksPerYear': booksPerYear,
      'favoriteGenres': favoriteGenres,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'onboardingComplete': onboardingComplete,
      'preferredLanguage': preferredLanguage,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      age: json['age'] as int?,
      education: json['education'] as String?,
      booksPerYear: json['booksPerYear'] as int?,
      favoriteGenres: (json['favoriteGenres'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      onboardingComplete: json['onboardingComplete'] as bool?,
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }
}