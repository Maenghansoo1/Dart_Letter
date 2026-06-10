class AuthUser {
  final String userId;
  final String email;
  final String nickname;
  final String accessToken;
  final String refreshToken;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        userId: json['user_id'] as String,
        email: json['email'] as String,
        nickname: (json['nickname'] as String?) ?? '익명',
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );

  AuthUser copyWith({String? nickname, String? accessToken, String? refreshToken}) =>
      AuthUser(
        userId: userId,
        email: email,
        nickname: nickname ?? this.nickname,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
      );
}
