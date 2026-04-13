import 'package:shared_preferences/shared_preferences.dart';

/// Persists the auth token across app restarts using SharedPreferences.
class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  static const _tokenKey = 'auth_token';

  String? _token;

  String? get token => _token;

  set token(String? value) {
    _token = value;
    _persist(value);
  }

  /// Call once at app startup to restore a previously saved token.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> clear() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> _persist(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
  }
}
