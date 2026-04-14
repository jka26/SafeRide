import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/student_model.dart';
import '../models/bus_model.dart';
import '../models/trip_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/attendance_service.dart';
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';
import '../services/trip_service.dart';

enum DashboardStatus { idle, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    DashboardService? dashboardService,
    NotificationService? notificationService,
    AttendanceService? attendanceService,
    TripService? tripService,
  })  : _dashboardService = dashboardService ?? DashboardService(),
        _notificationService = notificationService ?? NotificationService(),
        _attendanceService = attendanceService ?? AttendanceService(),
        _tripService = tripService ?? TripService();

  final DashboardService _dashboardService;
  final NotificationService _notificationService;
  final AttendanceService _attendanceService;
  final TripService _tripService;
  DashboardStatus _status = DashboardStatus.idle;
  String? _errorMessage;
  bool _isTogglingTrip = false;
  Timer? _locationTimer;
  String? _locationTripId;
  static const Duration _locationInterval = Duration(seconds: 15);

  // ── Shared ─────────────────────────────────────────────────
  UserModel? _currentUser;

  // ── Parent-specific ────────────────────────────────────────
  List<StudentModel> _children = [];
  int _selectedChildIndex = 0;
  StudentModel? _child;
  TripModel? _activeTrip;
  List<NotificationModel> _notifications = [];
  int _unreadNotifications = 0;

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
  List<StudentModel> get children => _children;
  int get selectedChildIndex => _selectedChildIndex;
  TripModel? get activeTrip => _activeTrip;
  List<NotificationModel> get notifications => _notifications;
  int get unreadNotifications => _unreadNotifications;

  List<StudentModel> get students => _students;
  bool get tripStarted => _tripStarted;
  int get checkedIn =>
      _students.where((s) => s.status == 'boarded' || s.status == 'alighted').length;
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
    _resetDashboardState();
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
        default:
          throw StateError('Unsupported dashboard role: $role');
      }
      await refreshNotifications();
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
    _children = data.children;
    _selectedChildIndex = 0;
    _setSelectedChildData();
  }

  Future<void> _loadDriverData() async {
    final data = await _dashboardService.getDriverDashboard();
    _currentUser = data.currentUser;
    _students = data.students;
    _activeTrip = data.activeTrip;
    _tripStarted = _activeTrip?.status == 'active';
    await _ensureDriverLocationSharing();
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
  Future<void> toggleTrip() async {
    final tripId = _activeTrip?.id;
    if (tripId == null || tripId.isEmpty || _isTogglingTrip) return;
    _isTogglingTrip = true;

    try {
      if (_tripStarted) {
        await _tripService.endTrip(tripId);
      } else {
        await _tripService.startTrip(tripId);
      }
      _tripStarted = !_tripStarted;
      await _ensureDriverLocationSharing();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isTogglingTrip = false;
    }
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
      final backendStatus = switch (newStatus) {
        'absent' => AttendanceApiStatus.absent,
        'boarded' => AttendanceApiStatus.boarded,
        'alighted' => AttendanceApiStatus.alighted,
        'pending' => AttendanceApiStatus.present,
        _ => AttendanceApiStatus.present,
      };
      await _attendanceService.markAttendance(
        studentId: studentId,
        tripId: tripId,
        status: backendStatus,
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

  Future<List<StudentModel>> getBusStudents(String busId) {
    return _dashboardService.getBusStudents(busId);
  }

  Future<void> refreshNotifications() async {
    _notifications = await _notificationService.getNotifications();
    _unreadNotifications = await _notificationService.getUnreadCount();
  }

  Future<void> markNotificationRead(String id) async {
    await _notificationService.markRead(id);
    await refreshNotifications();
    notifyListeners();
  }

  void selectChild(int index) {
    if (index < 0 || index >= _children.length) return;
    _selectedChildIndex = index;
    _setSelectedChildData();
    notifyListeners();
  }

  void _setSelectedChildData() {
    if (_children.isEmpty) {
      _child = null;
      _activeTrip = null;
      return;
    }
    _child = _children[_selectedChildIndex];
    _activeTrip = _child?.latestTrip;
  }

  void _resetDashboardState() {
    _stopLocationSharing();
    _currentUser = null;
    _children = [];
    _selectedChildIndex = 0;
    _child = null;
    _activeTrip = null;
    _notifications = [];
    _unreadNotifications = 0;
    _students = [];
    _tripStarted = false;
    _buses = [];
    _totalStudentsOnBoard = 0;
    _activeAlerts = 0;
    _completedTrips = 0;
    _activeRoutes = 0;
    _onTimeRate = 0;
  }

  void clearDashboardState() {
    _resetDashboardState();
    _status = DashboardStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _ensureDriverLocationSharing() async {
    final tripId = _activeTrip?.id;
    if (!_tripStarted || tripId == null || tripId.isEmpty) {
      _stopLocationSharing();
      return;
    }
    if (_locationTripId == tripId && _locationTimer != null) {
      return;
    }
    _stopLocationSharing();
    _locationTripId = tripId;
    await _reportCurrentLocation(tripId);
    _locationTimer = Timer.periodic(_locationInterval, (_) {
      _reportCurrentLocation(tripId);
    });
  }

  Future<void> _reportCurrentLocation(String tripId) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _tripService.reportLocation(
        tripId: tripId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Location reporting failed: $e');
    }
  }

  void _stopLocationSharing() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationTripId = null;
  }

  @override
  void dispose() {
    _stopLocationSharing();
    super.dispose();
  }
}
