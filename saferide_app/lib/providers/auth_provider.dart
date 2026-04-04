import 'package:flutter/foundation.dart';

enum UserRole { parent, driver, admin }
enum AuthMethod { emailPassword, phoneOtp }
enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  UserRole? _selectedRole;
  AuthMethod _authMethod = AuthMethod.emailPassword;
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  bool _isOtpSent = false;
  String? _phoneNumber;

  // Getters
  UserRole? get selectedRole => _selectedRole;
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
    await Future.delayed(const Duration(seconds: 2)); // Replace with real API call

    if (email.isNotEmpty && password.length >= 6) {
      _status = AuthStatus.success;
      _errorMessage = null;
    } else {
      _setError('Invalid email or password. Please try again.');
    }
    notifyListeners();
  }

  // Sign up
  Future<void> signUpWithEmail(String email, String password) async {
    _setLoading();
    await Future.delayed(const Duration(seconds: 2)); // Replace with real API call

    if (email.isNotEmpty && password.length >= 6) {
      _status = AuthStatus.success;
      _errorMessage = null;
    } else {
      _setError('Could not create account. Please check your details.');
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
  void signOut() {
    _selectedRole = null;
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
}