import '../api/api_client.dart';

class TripService {
  TripService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> startTrip(String tripId) async {
    await _apiClient.post('/driver/trips/$tripId/start');
  }

  Future<void> endTrip(String tripId) async {
    await _apiClient.post('/driver/trips/$tripId/end');
  }

  Future<void> reportLocation({
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    await _apiClient.post(
      '/driver/trips/$tripId/location',
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }
}
