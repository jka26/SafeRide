import '../api/api_client.dart';

enum AttendanceApiStatus { present, absent, boarded, alighted }

class AttendanceService {
  AttendanceService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> markAttendance({
    required String studentId,
    required String tripId,
    required AttendanceApiStatus status,
  }) async {
    await _apiClient.post(
      '/attendance',
      body: {
        'studentId': studentId,
        'tripId': tripId,
        'status': _statusToApi(status),
      },
    );
  }

  String _statusToApi(AttendanceApiStatus status) {
    switch (status) {
      case AttendanceApiStatus.present:
        return 'PRESENT';
      case AttendanceApiStatus.absent:
        return 'ABSENT';
      case AttendanceApiStatus.boarded:
        return 'BOARDED';
      case AttendanceApiStatus.alighted:
        return 'ALIGHTED';
    }
  }
}
