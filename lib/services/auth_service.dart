import '../models/auth_user.dart';
import 'api_service.dart';

class AuthService {
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await ApiService.instance.post('/auth/signup', data: {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.instance.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthUser> refreshToken(String refreshToken) async {
    final data = await ApiService.instance.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMe() async {
    final data = await ApiService.instance.get('/auth/me');
    return data as Map<String, dynamic>;
  }

  Future<void> updateNickname(String nickname) async {
    await ApiService.instance.patch('/auth/nickname', data: {'nickname': nickname});
  }
}
