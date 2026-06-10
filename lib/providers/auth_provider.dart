import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ─── 상태 ─────────────────────────────────────────────────────────────────────

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
  String get nickname => user?.nickname ?? '익명';

  AuthState copyWith({AuthUser? user, bool? isLoading, String? error, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  final _svc = AuthService();

  @override
  AuthState build() => const AuthState();

  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _svc.signup(email: email, password: password, nickname: nickname);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _svc.login(email: email, password: password);
      ApiService.instance.setAuthToken(user.accessToken);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> refreshIfNeeded() async {
    final refreshToken = state.user?.refreshToken;
    if (refreshToken == null) return;
    try {
      final user = await _svc.refreshToken(refreshToken);
      ApiService.instance.setAuthToken(user.accessToken);
      state = state.copyWith(user: user);
    } catch (_) {
      // 갱신 실패 → 로그아웃
      signOut();
    }
  }

  void signOut() {
    ApiService.instance.setAuthToken(null);
    state = const AuthState();
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('이메일 인증')) return '이메일 인증을 완료해주세요';
    if (msg.contains('이미 사용')) return '이미 사용 중인 이메일입니다';
    if (msg.contains('올바르지 않')) return '이메일 또는 비밀번호가 올바르지 않습니다';
    if (msg.contains('서버')) return '서버 오류가 발생했습니다';
    return '오류가 발생했습니다. 다시 시도해주세요';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
