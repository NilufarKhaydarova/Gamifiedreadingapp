import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart' as models;
import '../../data/services/database_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final models.User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    models.User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─── Database Service Provider ────────────────────────────────────────────────

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  late DatabaseService _db;

  @override
  AuthState build() {
    _db = ref.read(databaseServiceProvider);
    // Defer until after build() returns so the provider is fully initialized
    // before _init() synchronously touches `state`.
    Future.microtask(_init);
    return const AuthState();
  }

  Future<void> _init() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _db.getCurrentUser();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _db.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _db.signIn(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _db.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, status: AuthStatus.unauthenticated);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

final authUserProvider = Provider<models.User?>((ref) {
  return ref.watch(authProvider).user;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});
