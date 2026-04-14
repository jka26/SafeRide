import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

enum OnboardingStatus { idle, loading, success, error }

class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
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
    try {
      await _apiClient.post(
        '/onboarding/parent',
        body: {
          'childName': childName,
          'grade': childGrade,
          'stopName': stopName,
          'emergencyContactName': emergencyContactName,
          'emergencyContactPhone': emergencyContactPhone,
        },
      );
      _status = OnboardingStatus.success;
      notifyListeners();
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> submitDriverDetails({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    _setLoading();
    try {
      await _apiClient.post(
        '/onboarding/driver',
        body: {
          'emergencyContactName': emergencyContactName,
          'emergencyContactPhone': emergencyContactPhone,
        },
      );
      _status = OnboardingStatus.success;
      notifyListeners();
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
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