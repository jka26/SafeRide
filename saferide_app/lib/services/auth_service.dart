import '../api/api_client.dart';
import '../api/session_store.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;

    SessionStore.instance.token = response['token']?.toString();
    return UserModel.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '/auth/signup',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role.toUpperCase(),
      },
    ) as Map<String, dynamic>;

    return UserModel.fromJson(response);
  }

  Future<UserModel> me() async {
    final response = await _apiClient.get('/auth/me') as Map<String, dynamic>;
    return UserModel.fromJson(response);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } finally {
      SessionStore.instance.clear();
    }
  }
}
