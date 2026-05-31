import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final String? userId;
  final String? email;
  final bool isLoading;

  const AuthState({this.userId, this.email, this.isLoading = false});

  bool get isLoggedIn => userId != null;

  AuthState copyWith({String? userId, String? email, bool? isLoading}) => AuthState(
        userId: userId ?? this.userId,
        email: email ?? this.email,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    // TODO: Supabase auth.signInWithPassword
    state = state.copyWith(isLoading: false);
  }

  Future<void> signOut() async {
    // TODO: Supabase auth.signOut
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
