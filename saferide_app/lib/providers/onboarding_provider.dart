import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/student_model.dart';

enum OnboardingStatus { idle, loading, success, error }

enum SearchStatus { idle, loading, found, error }

class OnboardingProvider extends ChangeNotifier {
  final ApiClient _api;

  OnboardingProvider({ApiClient? api}) : _api = api ?? ApiClient();

  // ── Link state (used when parent taps "Link my child") ──────
  OnboardingStatus _status = OnboardingStatus.idle;
  String? _errorMessage;

  OnboardingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == OnboardingStatus.loading;
  bool get isSuccess => _status == OnboardingStatus.success;

  // ── Search state (used when parent searches by code) ────────
  SearchStatus _searchStatus = SearchStatus.idle;
  String? _searchError;
  StudentSearchResult? _searchResult;

  SearchStatus get searchStatus => _searchStatus;
  String? get searchError => _searchError;
  StudentSearchResult? get searchResult => _searchResult;
  bool get isSearching => _searchStatus == SearchStatus.loading;

  // ── Search student by code ───────────────────────────────────
  Future<void> searchStudent(String code) async {
    _searchStatus = SearchStatus.loading;
    _searchError = null;
    _searchResult = null;
    notifyListeners();

    try {
      final data = await _api.get(
        '/parents/me/students/search',
        queryParameters: {'code': code},
      );
      _searchResult = StudentSearchResult.fromJson(data as Map<String, dynamic>);
      _searchStatus = SearchStatus.found;
    } on ApiException catch (e) {
      _searchError = e.message;
      _searchStatus = SearchStatus.error;
    } catch (_) {
      _searchError = 'Could not connect to server. Check your connection.';
      _searchStatus = SearchStatus.error;
    }

    notifyListeners();
  }

  // ── Link student to this parent ──────────────────────────────
  Future<void> linkStudent(String studentId) async {
    _status = OnboardingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/parents/me/students/$studentId');
      _status = OnboardingStatus.success;
    } on ApiException catch (e) {
      _status = OnboardingStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = OnboardingStatus.error;
      _errorMessage = 'Could not connect to server. Check your connection.';
    }

    notifyListeners();
  }

  // ── Driver onboarding (still mocked until backend is ready) ─
  Future<void> submitDriverDetails({
    required String fullName,
    required String phone,
    required String busNumber,
    required String routeName,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    _status = OnboardingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // TODO: replace with real API call
    // POST /onboarding/driver
    await Future.delayed(const Duration(seconds: 2));
    _status = OnboardingStatus.success;
    notifyListeners();
  }

  // ── Reset helpers ────────────────────────────────────────────
  void resetSearch() {
    _searchStatus = SearchStatus.idle;
    _searchError = null;
    _searchResult = null;
    notifyListeners();
  }

  void reset() {
    _status = OnboardingStatus.idle;
    _errorMessage = null;
    resetSearch();
  }
}
