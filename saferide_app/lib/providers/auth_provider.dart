import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/session_store.dart';

enum UserRole { parent, driver, admin }

enum AuthStatus { idle, loading, success, error }

class AuthenticatedUser {
  final String id;
  final String email;
  final String role;
  final String fullName;
  final bool onboardingCompleted;

  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    required this.onboardingCompleted,
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    final normalizedRole = (json['role'] ?? 'PARENT')
        .toString()
        .trim()
        .toLowerCase();
    return AuthenticatedUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: normalizedRole,
      fullName: json['fullName'] ?? '',
      onboardingCompleted: json['onboardingCompleted'] == true,
    );
  }

  UserRole get userRole {
    switch (role) {
      case 'driver': return UserRole.driver;
      case 'admin':  return UserRole.admin;
      default:       return UserRole.parent;
    }
  }
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  AuthenticatedUser? _currentUser;
  String? _sessionToken;

  // ── Getters ────────────────────────────────────────────────
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  AuthenticatedUser? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoading => _status == AuthStatus.loading;
  bool get hasError => _status == AuthStatus.error;
  bool get isAuthenticated => _sessionToken != null && _currentUser != null;

  // Convenience getter — used by DashboardScreen
  UserRole? get selectedRole => _currentUser?.userRole;

  /// Call this on app start to restore a saved session.
  /// Returns true if a valid session was found, false otherwise.
  Future<bool> restoreSession() async {
    final saved = SessionStore.instance.token;
    if (saved == null || saved.isEmpty) return false;

    try {
      SessionStore.instance.token = saved;
      final body = await _apiClient.get('/auth/me') as Map<String, dynamic>;
      _currentUser = AuthenticatedUser.fromJson(body);
      _sessionToken = saved;
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (_) {
      await SessionStore.instance.clear();
      _sessionToken = null;
      _currentUser = null;
      _status = AuthStatus.idle;
      _errorMessage = null;
      return false;
    }
  }

  // ── Sign Up ────────────────────────────────────────────────
  // Backend expects: { email, password, role, fullName }
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'parent' or 'driver'
  }) async {
    if (_status == AuthStatus.loading) return;
    _setLoading();

    try {
      final body = await _apiClient.post(
        '/auth/signup',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role.trim().toUpperCase(),
        },
      ) as Map<String, dynamic>;

      _sessionToken = body['token']?.toString();
      final userData = (body['user'] as Map?)?.cast<String, dynamic>() ?? body;
      _currentUser = AuthenticatedUser.fromJson(userData);
      if (_sessionToken != null && _sessionToken!.isNotEmpty) {
        SessionStore.instance.token = _sessionToken;
      }
      _status = AuthStatus.success;
      _errorMessage = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }

    notifyListeners();
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    required String fullName,
  }) {
    return signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: 'PARENT',
    );
  }

  // ── Login ──────────────────────────────────────────────────
  // Backend expects: { email, password }
  Future<void> loginWithEmail(String email, String password) async {
    if (_status == AuthStatus.loading) return;
    _setLoading();

    try {
      final body = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      ) as Map<String, dynamic>;

      _sessionToken = body['token']?.toString();
      final userData = (body['user'] as Map?)?.cast<String, dynamic>() ?? body;
      _currentUser = AuthenticatedUser.fromJson(userData);
      if (_sessionToken != null && _sessionToken!.isNotEmpty) {
        SessionStore.instance.token = _sessionToken;
      }
      _status = AuthStatus.success;
      _errorMessage = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }

    notifyListeners();
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> signOut() async {
    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      try {
        await _apiClient.post('/auth/logout');
      } catch (_) {
        // Even if server logout fails, local sign-out should proceed.
      }
    }

    await SessionStore.instance.clear();
    _sessionToken = null;
    _currentUser = null;
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
  }
}