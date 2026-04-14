import '../api/api_client.dart';

class AdminDriverOption {
  const AdminDriverOption({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;
}

class AdminBusOption {
  const AdminBusOption({
    required this.id,
    required this.plateNumber,
    required this.routeName,
  });

  final String id;
  final String plateNumber;
  final String routeName;
}

class AdminOpsService {
  AdminOpsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AdminDriverOption>> listDrivers() async {
    final response = await _apiClient.get('/users') as List<dynamic>;
    return response
        .cast<Map<String, dynamic>>()
        .where((u) => (u['role'] ?? '').toString().toUpperCase() == 'DRIVER')
        .map((u) {
          final driver = u['driver'] as Map<String, dynamic>?;
          // Trip.driverId references Driver.id, not User.id.
          final profileId = (driver?['id'] ?? '').toString();
          return AdminDriverOption(
            id: profileId,
            fullName: (u['fullName'] ?? 'Unnamed driver').toString(),
            email: (u['email'] ?? '').toString(),
          );
        })
        .where((d) => d.id.isNotEmpty)
        .toList();
  }

  Future<List<AdminBusOption>> listBuses() async {
    final response = await _apiClient.get('/buses') as List<dynamic>;
    return response
        .cast<Map<String, dynamic>>()
        .map(
          (b) => AdminBusOption(
            id: (b['id'] ?? '').toString(),
            plateNumber: (b['plateNumber'] ?? '--').toString(),
            routeName: (b['routeName'] ?? '--').toString(),
          ),
        )
        .where((b) => b.id.isNotEmpty)
        .toList();
  }

  Future<void> createBus({
    required String plateNumber,
    required String routeName,
    required int capacity,
  }) async {
    await _apiClient.post(
      '/buses',
      body: {
        'plateNumber': plateNumber,
        'routeName': routeName,
        'capacity': capacity,
      },
    );
  }

  Future<void> createTripAssignment({
    required String name,
    required String busId,
    required String driverId,
    required DateTime tripDate,
  }) async {
    await _apiClient.post(
      '/trips',
      body: {
        'name': name,
        'busId': busId,
        'driverId': driverId,
        'tripDate': tripDate.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> startTrip(String tripId) async {
    await _apiClient.post('/driver/trips/$tripId/start');
  }
}
