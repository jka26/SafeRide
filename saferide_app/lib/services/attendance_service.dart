import '../api/api_client.dart';

class AttendanceService {
  AttendanceService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> markAttendance({
    required String studentId,
    required String tripId,
    required String status,
  }) async {
    await _apiClient.post(
      '/attendance',
      body: {
        'studentId': studentId,
        'tripId': tripId,
        'status': status.toUpperCase(),
      },
    );
  }
}
