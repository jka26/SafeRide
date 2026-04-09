import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum UserRole { parent, driver, admin }
enum AuthMethod { emailPassword, phoneOtp }
enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;
  UserRole? _selectedRole;
  UserModel? _currentUser;
  AuthMethod _authMethod = AuthMethod.emailPassword;
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  bool _isOtpSent = false;
  String? _phoneNumber;

  // Getters
  UserRole? get selectedRole => _selectedRole;
  UserModel? get currentUser => _currentUser;
  AuthMethod get authMethod => _authMethod;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isOtpSent => _isOtpSent;
  String? get phoneNumber => _phoneNumber;
  bool get isLoading => _status == AuthStatus.loading;
  bool get hasError => _status == AuthStatus.error;

  // Role selection
  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  // Auth method toggle
  void switchAuthMethod(AuthMethod method) {
    _authMethod = method;
    _isOtpSent = false;
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // Email / Password login
  Future<void> loginWithEmail(String email, String password) async {
    _setLoading();
    try {
      _currentUser = await _authService.login(email: email, password: password);
      _selectedRole = _roleFromString(_currentUser?.role);
      _status = AuthStatus.success;
      _errorMessage = null;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  // Sign up
  Future<void> signUpWithEmail(
    String email,
    String password, {
    required String fullName,
  }) async {
    _setLoading();
    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: (_selectedRole ?? UserRole.parent).name,
      );
      _selectedRole = _roleFromString(_currentUser?.role);
      _status = AuthStatus.success;
      _errorMessage = null;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  // Phone OTP
  Future<void> sendOtp(String phone) async {
    _setLoading();
    await Future.delayed(const Duration(seconds: 1));

    _phoneNumber = phone;
    _isOtpSent = true;
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> verifyOtp(String otp) async {
    _setLoading();
    await Future.delayed(const Duration(seconds: 2));

    if (otp == '123456') {
      _status = AuthStatus.success;
      _errorMessage = null;
    } else {
      _setError('Invalid OTP. Please check and try again.');
    }
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.logout();
    _selectedRole = null;
    _currentUser = null;
    _status = AuthStatus.idle;
    _errorMessage = null;
    _isOtpSent = false;
    _phoneNumber = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // Private helpers
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
  }

  UserRole? _roleFromString(String? role) {
    switch ((role ?? '').toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'DRIVER':
        return UserRole.driver;
      case 'PARENT':
        return UserRole.parent;
      default:
        return null;
    }
  }
}
