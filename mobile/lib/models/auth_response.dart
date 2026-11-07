import '../utils/json_read.dart';
import 'user.dart';

/// Response of `/auth/register` and `/auth/login`.
class AuthResponse {
  const AuthResponse({
    required this.token,
    this.tokenType = 'Bearer',
    this.expiresInMs = 0,
    required this.user,
  });

  final String token;
  final String tokenType;
  final int expiresInMs;
  final User user;

  factory AuthResponse.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    return AuthResponse(
      token: stringOr(data['token'], ''),
      tokenType: stringOr(data['tokenType'], 'Bearer'),
      expiresInMs: intOr(data['expiresInMs'], 0),
      user: User.fromJson(asMap(data['user'])),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'token': token,
        'tokenType': tokenType,
        'expiresInMs': expiresInMs,
        'user': user.toJson(),
      };
}
