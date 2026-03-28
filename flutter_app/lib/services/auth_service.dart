import '../models/user_session.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<UserSession> login(String email, String password) async {
    final data = await _client.post('/api/user/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    final user = data['user'] as Map<String, dynamic>? ?? {};
    return UserSession.fromJson({
      ...user,
      'token': data['token'],
    });
  }

  Future<void> signup(String username, String email, String password) async {
    await _client.post('/api/user/signup', {
      'username': username,
      'email': email,
      'password': password,
    });
  }
}
