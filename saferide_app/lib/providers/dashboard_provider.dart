import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/bus_model.dart';
import '../models/trip_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/attendance_service.dart';
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';

enum DashboardStatus { idle, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    DashboardService? dashboardService,
    NotificationService? notificationService,
    AttendanceService? attendanceService,
  })  : _dashboardService = dashboardService ?? DashboardService(),
        _notificationService = notificationService ?? NotificationService(),
        _attendanceService = attendanceService ?? AttendanceService();

  final DashboardService _dashboardService;
  final NotificationService _notificationService;
  final AttendanceService _attendanceService;
  DashboardStatus _status = DashboardStatus.idle;
  String? _errorMessage;

  // ── Shared ─────────────────────────────────────────────────
  UserModel? _currentUser;

  // ── Parent-specific ────────────────────────────────────────
  StudentModel? _child;
  TripModel? _activeTrip;
  List<NotificationModel> _notifications = [];

  // ── Driver-specific ────────────────────────────────────────
  List<StudentModel> _students = [];
  bool _tripStarted = false;

  // ── Admin-specific ─────────────────────────────────────────
  List<BusModel> _buses = [];
  int _totalStudentsOnBoard = 0;
  int _activeAlerts = 0;
  int _completedTrips = 0;
  int _activeRoutes = 0;
  double _onTimeRate = 0.0;

  // ── Getters ────────────────────────────────────────────────
  DashboardStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == DashboardStatus.loading;

  UserModel? get currentUser => _currentUser;
  StudentModel? get child => _child;
  TripModel? get activeTrip => _activeTrip;
  List<NotificationModel> get notifications => _notifications;

  List<StudentModel> get students => _students;
  bool get tripStarted => _tripStarted;
  int get checkedIn =>
      _students.where((s) => s.status == 'boarded').length;
  int get pending =>
      _students.where((s) => s.status == 'pending').length;
  int get absent =>
      _students.where((s) => s.status == 'absent').length;

  List<BusModel> get buses => _buses;
  int get totalStudentsOnBoard => _totalStudentsOnBoard;
  int get activeAlerts => _activeAlerts;
  int get completedTrips => _completedTrips;
  int get activeRoutes => _activeRoutes;
  double get onTimeRate => _onTimeRate;
  int get activeBuses =>
      _buses.where((b) => b.status == 'active').length;

  // ── Load dashboard based on role ───────────────────────────
  Future<void> loadDashboard(String role) async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (role) {
        case 'parent':
          await _loadParentData();
          break;
        case 'driver':
          await _loadDriverData();
          break;
        case 'admin':
          await _loadAdminData();
          break;
      }
      _notifications = await _notificationService.getNotifications();
      _status = DashboardStatus.loaded;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> _loadParentData() async {
    final data = await _dashboardService.getParentDashboard();
    _currentUser = data.currentUser;
    _child = data.children.isNotEmpty ? data.children.first : null;
    _activeTrip = data.activeTrip;
  }

  Future<void> _loadDriverData() async {
    final data = await _dashboardService.getDriverDashboard();
    _currentUser = data.currentUser;
    _students = data.students;
    _activeTrip = data.activeTrip;
    _tripStarted = _activeTrip != null;
  }

  Future<void> _loadAdminData() async {
    final data = await _dashboardService.getAdminDashboard();
    _currentUser = data.currentUser;
    _buses = data.buses;
    _totalStudentsOnBoard = data.totalStudentsOnBoard;
    _activeAlerts = data.activeAlerts;
    _completedTrips = data.completedTrips;
    _activeRoutes = data.activeRoutes;
    _onTimeRate = data.onTimeRate;
  }

  // ── Driver actions ─────────────────────────────────────────
  void toggleTrip() {
    _tripStarted = !_tripStarted;
    notifyListeners();
  }

  Future<void> updateStudentStatus(String studentId, String newStatus) async {
    final tripId = _activeTrip?.id;
    if (tripId == null) {
      _errorMessage = 'No trip is available for attendance updates.';
      notifyListeners();
      return;
    }

    try {
      await _attendanceService.markAttendance(
        studentId: studentId,
        tripId: tripId,
        status: newStatus == 'absent' ? 'ABSENT' : 'PRESENT',
      );
      _students = _students.map((s) {
        if (s.id == studentId) {
          return StudentModel(
            id: s.id,
            name: s.name,
            grade: s.grade,
            stopId: s.stopId,
            stopName: s.stopName,
            dropOffTime: s.dropOffTime,
            status: newStatus,
            latestTrip: s.latestTrip,
          );
        }
        return s;
      }).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
