import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_config.dart';

enum UserRole { parent, driver, admin }

enum AuthStatus { idle, loading, success, error }

class AuthenticatedUser {
  final String id;
  final String email;
  final String role;
  final String fullName;

  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'parent',
      fullName: json['fullName'] ?? '',
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

  // ── Persist session to local storage ──────────────────────
  Future<void> _saveSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
  }

  /// Call this on app start to restore a saved session.
  /// Returns true if a valid session was found, false otherwise.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('session_token');
    if (saved == null || saved.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {
          'Authorization': 'Bearer $saved',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = AuthenticatedUser.fromJson(json);
        _sessionToken = saved;
        _status = AuthStatus.success;
        notifyListeners();
        return true;
      } else {
        // Token expired or invalid — clear it
        await _clearSession();
        return false;
      }
    } catch (_) {
      await _clearSession();
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
    _setLoading();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        _sessionToken = body['token'];
        _currentUser = AuthenticatedUser.fromJson(body['user']);
        await _saveSession(_sessionToken!);
        _status = AuthStatus.success;
        _errorMessage = null;
      } else {
        // Backend error — e.g. 409 ConflictException "Email already in use"
        _setError(body['message'] ?? 'Sign up failed. Please try again.');
      }
    } catch (e) {
      _setError('Could not connect to server. Check your connection.');
    }

    notifyListeners();
  }

  // ── Login ──────────────────────────────────────────────────
  // Backend expects: { email, password }
  Future<void> loginWithEmail(String email, String password) async {
    _setLoading();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _sessionToken = body['token'];
        _currentUser = AuthenticatedUser.fromJson(body['user']);
        await _saveSession(_sessionToken!);
        _status = AuthStatus.success;
        _errorMessage = null;
      } else {
        // 401 UnauthorizedException "Invalid credentials"
        _setError(body['message'] ?? 'Invalid email or password.');
      }
    } catch (e) {
      _setError('Could not connect to server. Check your connection.');
    }

    notifyListeners();
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> signOut() async {
    if (_sessionToken != null) {
      try {
        // Tell the backend to delete the session from the DB
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: {
            'Authorization': 'Bearer $_sessionToken',
            'Content-Type': 'application/json',
          },
        );
      } catch (_) {
        // Even if the server call fails, clear local state
      }
    }

    _sessionToken = null;
    _currentUser = null;
    _status = AuthStatus.idle;
    _errorMessage = null;
    await _clearSession();
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