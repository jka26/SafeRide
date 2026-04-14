import '../api/api_client.dart';
import '../models/bus_model.dart';
import '../models/student_model.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';

class ParentDashboardData {
  ParentDashboardData({
    required this.currentUser,
    required this.children,
    required this.activeTrip,
  });

  final UserModel currentUser;
  final List<StudentModel> children;
  final TripModel? activeTrip;
}

class DriverDashboardData {
  DriverDashboardData({
    required this.currentUser,
    required this.students,
    required this.activeTrip,
  });

  final UserModel currentUser;
  final List<StudentModel> students;
  final TripModel? activeTrip;
}

class AdminDashboardData {
  AdminDashboardData({
    required this.currentUser,
    required this.buses,
    required this.totalStudentsOnBoard,
    required this.activeAlerts,
    required this.completedTrips,
    required this.activeRoutes,
    required this.onTimeRate,
  });

  final UserModel currentUser;
  final List<BusModel> buses;
  final int totalStudentsOnBoard;
  final int activeAlerts;
  final int completedTrips;
  final int activeRoutes;
  final double onTimeRate;
}

class DashboardService {
  DashboardService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ParentDashboardData> getParentDashboard() async {
    final response = await _apiClient.get('/dashboard/parent') as Map<String, dynamic>;
    final user = await _currentUser();
    final childrenJson = (response['children'] ?? []) as List<dynamic>;
    final children = childrenJson
        .map((item) => StudentModel.fromParentDashboard(item as Map<String, dynamic>))
        .toList();

    return ParentDashboardData(
      currentUser: user,
      children: children,
      activeTrip: children.isNotEmpty ? children.first.latestTrip : null,
    );
  }

  Future<DriverDashboardData> getDriverDashboard() async {
    final response = await _apiClient.get('/dashboard/driver') as Map<String, dynamic>;
    final user = await _currentUser();
    final todaysTrips = (response['todaysTrips'] ?? []) as List<dynamic>;

    if (todaysTrips.isEmpty) {
      return DriverDashboardData(
        currentUser: user,
        students: const [],
        activeTrip: null,
      );
    }

    final firstTrip = todaysTrips.first as Map<String, dynamic>;
    final attendances = (firstTrip['attendances'] ?? []) as List<dynamic>;

    return DriverDashboardData(
      currentUser: user,
      students: attendances
          .map((item) => StudentModel.fromDriverAttendance(item as Map<String, dynamic>))
          .toList(),
      activeTrip: TripModel.fromDriverDashboard(firstTrip),
    );
  }

  Future<AdminDashboardData> getAdminDashboard() async {
    final response = await _apiClient.get('/dashboard/admin') as Map<String, dynamic>;
    final user = await _currentUser();
    final counts = (response['counts'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final todaysAttendance = (response['todaysAttendance'] ?? const <String, dynamic>{})
        as Map<String, dynamic>;
    final todaysTrips = (response['todaysTrips'] ?? []) as List<dynamic>;
    final recentNotifications =
        (response['recentNotifications'] ?? []) as List<dynamic>;
    final metrics = (response['metrics'] ?? const <String, dynamic>{})
        as Map<String, dynamic>;

    final present = (todaysAttendance['present'] as num?)?.toInt() ?? 0;
    final absent = (todaysAttendance['absent'] as num?)?.toInt() ?? 0;
    final totalMarked = present + absent;

    return AdminDashboardData(
      currentUser: user,
      buses: todaysTrips
          .map((item) => BusModel.fromAdminTrip(item as Map<String, dynamic>))
          .toList(),
      totalStudentsOnBoard:
          (metrics['studentsOnBoard'] as num?)?.toInt() ?? present,
      activeAlerts: recentNotifications.length,
      completedTrips:
          (metrics['completedTrips'] as num?)?.toInt() ?? todaysTrips.length,
      activeRoutes: (metrics['activeRoutes'] as num?)?.toInt() ??
          (counts['buses'] as num?)?.toInt() ??
          0,
      onTimeRate:
          (metrics['onTimeRate'] as num?)?.toDouble() ??
              (totalMarked == 0 ? 0 : (present / totalMarked) * 100),
    );
  }

  Future<UserModel> _currentUser() async {
    final response = await _apiClient.get('/auth/me') as Map<String, dynamic>;
    return UserModel.fromJson(response);
  }
}
