import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../models/progress.dart';
import '../models/achievement.dart';

class SupabaseService {
  late final SupabaseClient _client;

  Future<void> initialize() async {
    _client = Supabase.instance.client;
  }

  // Authentication
  Future<models.User> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
      },
    );

    if (authResponse.user == null) {
      throw Exception('Sign up failed');
    }

    // Create user profile
    await _client.from('users').insert({
      'id': authResponse.user!.id,
      'email': email,
      'display_name': displayName,
      'created_at': DateTime.now().toIso8601String(),
    });

    return models.User(
      id: authResponse.user!.id,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  Future<models.User> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Sign in failed');
    }

    // Fetch user profile
    final userData = await _client
        .from('users')
        .select()
        .eq('id', authResponse.user!.id)
        .single();

    return models.User(
      id: userData['id'],
      email: userData['email'],
      displayName: userData['display_name'],
      createdAt: DateTime.parse(userData['created_at']),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<models.User?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final userData = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .single();

    return models.User(
      id: userData['id'],
      email: userData['email'],
      displayName: userData['display_name'],
      createdAt: DateTime.parse(userData['created_at']),
    );
  }

  // Real-time progress sync
  Stream<Progress?> watchProgress(String userId, String bookId) {
    return _client
        .from('reading_progress')
        .stream(primaryKey: const ['id'])
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .map((event) {
          if (event.isEmpty) return null;
          final data = event.first;
          return Progress(
            id: data['id'] ?? '',
            userId: data['user_id'] ?? '',
            bookId: data['book_id'] ?? '',
            currentDay: data['current_day'] ?? 0,
            totalDays: data['total_days'] ?? 30,
            completedDays: List<String>.from(data['completed_days'] ?? []),
            xp: data['xp'] ?? 0,
            level: data['level'] ?? 1,
            lastSessionDate: data['last_session_date'] != null
                ? DateTime.parse(data['last_session_date'])
                : null,
            streakDays: data['streak_days'] ?? 0,
            startDate: data['start_date'] != null
                ? DateTime.parse(data['start_date'])
                : null,
            completedDate: data['completed_date'] != null
                ? DateTime.parse(data['completed_date'])
                : null,
          );
        });
  }

  Future<Progress> getProgress(String userId, String bookId) async {
    final response = await _client
        .from('reading_progress')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();

    if (response == null) {
      // Create new progress
      final newProgress = {
        'user_id': userId,
        'book_id': bookId,
        'current_day': 0,
        'total_days': 30,
        'completed_days': [],
        'xp': 0,
        'level': 1,
        'streak_days': 0,
        'start_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('reading_progress').insert(newProgress);

      return Progress(
        id: '',
        userId: userId,
        bookId: bookId,
        currentDay: 0,
        totalDays: 30,
        completedDays: [],
        xp: 0,
        level: 1,
        streakDays: 0,
        startDate: DateTime.now(),
      );
    }

    return Progress(
      id: response['id'] ?? '',
      userId: response['user_id'] ?? '',
      bookId: response['book_id'] ?? '',
      currentDay: response['current_day'] ?? 0,
      totalDays: response['total_days'] ?? 30,
      completedDays: List<String>.from(response['completed_days'] ?? []),
      xp: response['xp'] ?? 0,
      level: response['level'] ?? 1,
      lastSessionDate: response['last_session_date'] != null
          ? DateTime.parse(response['last_session_date'])
          : null,
      streakDays: response['streak_days'] ?? 0,
      startDate: response['start_date'] != null
          ? DateTime.parse(response['start_date'])
          : null,
      completedDate: response['completed_date'] != null
          ? DateTime.parse(response['completed_date'])
          : null,
    );
  }

  Future<void> syncProgress(Progress progress) async {
    await _client.from('reading_progress').upsert({
      'id': progress.id.isNotEmpty ? progress.id : null,
      'user_id': progress.userId,
      'book_id': progress.bookId,
      'current_day': progress.currentDay,
      'total_days': progress.totalDays,
      'completed_days': progress.completedDays,
      'xp': progress.xp,
      'level': progress.level,
      'last_session_date': progress.lastSessionDate?.toIso8601String(),
      'streak_days': progress.streakDays,
      'start_date': progress.startDate?.toIso8601String(),
      'completed_date': progress.completedDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Achievements
  Future<List<Achievement>> fetchAchievements() async {
    final response = await _client
        .from('achievements')
        .select()
        .order('xp_reward', ascending: true);

    return response.map((json) => Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconUrl: json['icon_url'] ?? 'assets/icons/achievements/default.png',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == (json['category'] ?? 'streak'),
        orElse: () => AchievementCategory.streak,
      ),
      targetValue: json['target_value'],
      xpReward: json['xp_reward'],
    )).toList();
  }

  Future<List<Achievement>> fetchUserAchievements(String userId) async {
    final response = await _client
        .from('user_achievements')
        .select('*, achievements(*)')
        .eq('user_id', userId);

    return response.map((json) {
      final achievement = json['achievements'];
      return Achievement(
        id: achievement['id'],
        title: achievement['title'],
        description: achievement['description'],
        iconUrl: achievement['icon_url'] ?? 'assets/icons/achievements/default.png',
        category: AchievementCategory.values.firstWhere(
          (e) => e.name == (achievement['category'] ?? 'streak'),
          orElse: () => AchievementCategory.streak,
        ),
        targetValue: achievement['target_value'],
        xpReward: achievement['xp_reward'],
        unlockedAt: DateTime.parse(json['unlocked_at']),
      );
    }).toList();
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    await _client.from('user_achievements').insert({
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': DateTime.now().toIso8601String(),
    });
  }

  // Daily challenges
  Future<Map<String, dynamic>> getDailyChallenge(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _client
        .from('daily_challenges')
        .select()
        .eq('user_id', userId)
        .eq('date', today)
        .maybeSingle();

    if (response == null) {
      // Generate new daily challenge
      final newChallenge = {
        'user_id': userId,
        'date': today,
        'target_minutes': 15,
        'completed_minutes': 0,
        'completed': false,
        'xp_reward': 50,
      };

      await _client.from('daily_challenges').insert(newChallenge);
      return newChallenge;
    }

    return response;
  }

  Future<void> updateDailyChallenge(
    String userId,
    int additionalMinutes,
  ) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Get current challenge
    final current = await getDailyChallenge(userId);

    // Update with new progress
    await _client
        .from('daily_challenges')
        .update({
          'completed_minutes': (current['completed_minutes'] ?? 0) + additionalMinutes,
          'completed': (current['completed_minutes'] ?? 0) + additionalMinutes >= (current['target_minutes'] ?? 15),
        })
        .eq('user_id', userId)
        .eq('date', today);
  }

  // Leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await _client
        .from('users')
        .select('id, display_name, xp, level')
        .order('xp', ascending: false)
        .limit(100);

    return List<Map<String, dynamic>>.from(response);
  }

  // Check streak
  Future<int> getUserStreak(String userId) async {
    final response = await _client
        .from('reading_sessions')
        .select('created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(30);

    if (response.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;
    DateTime? checkDate;

    for (final session in response) {
      final sessionDate = DateTime.parse(session['created_at']);

      if (checkDate == null) {
        // First session - check if it's today or yesterday
        final daysDiff = now.difference(sessionDate).inDays;
        if (daysDiff <= 1) {
          streak++;
          checkDate = sessionDate;
        } else {
          break;
        }
      } else {
        final daysDiff = checkDate.difference(sessionDate).inDays;
        if (daysDiff <= 1) {
          streak++;
          checkDate = sessionDate;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  // Log reading session
  Future<void> logReadingSession({
    required String userId,
    required String bookId,
    required int minutesRead,
    required int dayNumber,
  }) async {
    await _client.from('reading_sessions').insert({
      'user_id': userId,
      'book_id': bookId,
      'minutes_read': minutesRead,
      'day_number': dayNumber,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
