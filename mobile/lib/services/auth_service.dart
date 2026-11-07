import '../models/auth_response.dart';
import '../models/user.dart';
import '../utils/json_read.dart';
import 'api_client.dart';

/// `/api/v1/auth` and `/api/v1/users` calls.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      '/api/v1/auth/register',
      body: <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim().isEmpty ? null : email.trim(),
        'password': password,
      },
    );
    return AuthResponse.fromJson(asMap(body));
  }

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final body = await _api.post(
      '/api/v1/auth/login',
      body: <String, dynamic>{
        'identifier': identifier.trim(),
        'password': password,
      },
    );
    return AuthResponse.fromJson(asMap(body));
  }

  Future<User> me() async {
    final body = await _api.get('/api/v1/users/me');
    return User.fromJson(asMap(body));
  }
}
