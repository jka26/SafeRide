import 'package:flutter/foundation.dart';

enum OnboardingStatus { idle, loading, success, error }

class OnboardingProvider extends ChangeNotifier {
  OnboardingStatus _status = OnboardingStatus.idle;
  String? _errorMessage;

  OnboardingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == OnboardingStatus.loading;
  bool get isSuccess => _status == OnboardingStatus.success;

  Future<void> submitParentDetails({
    required String fullName,
    required String phone,
    required String childName,
    required String childGrade,
    required String stopName,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    _setLoading();

    // MOCK — replace with real API call when backend is ready:
    // POST ${ApiConfig.baseUrl}/onboarding/parent
    // body: { fullName, phone, childName, childGrade, stopName,
    //         emergencyContact: { name, phone } }

    await Future.delayed(const Duration(seconds: 2));
    _status = OnboardingStatus.success;
    notifyListeners();
  }

  Future<void> submitDriverDetails({
    required String fullName,
    required String phone,
    required String busNumber,
    required String routeName,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    _setLoading();

    // MOCK — replace with real API call when backend is ready:
    // POST ${ApiConfig.baseUrl}/onboarding/driver
    // body: { fullName, phone, busNumber, routeName,
    //         emergencyContact: { name, phone } }

    await Future.delayed(const Duration(seconds: 2));
    _status = OnboardingStatus.success;
    notifyListeners();
  }

  void reset() {
    _status = OnboardingStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = OnboardingStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = OnboardingStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}