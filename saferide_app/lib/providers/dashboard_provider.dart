import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/bus_model.dart';
import '../models/trip_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

enum DashboardStatus { idle, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
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
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      switch (role) {
        case 'parent':
          _loadParentData();
          break;
        case 'driver':
          _loadDriverData();
          break;
        case 'admin':
          _loadAdminData();
          break;
      }
      _status = DashboardStatus.loaded;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = 'Failed to load dashboard. Please try again.';
    }
    notifyListeners();
  }

  // ── Mock data — replace with real API calls ────────────────

  void _loadParentData() {
    _currentUser = const UserModel(
      id: '1', name: 'Emma Johnson',
      email: 'parent@school.edu', role: 'parent',
    );
    _child = const StudentModel(
      id: 's1', name: 'Emma Johnson',
      grade: 'Grade 5', stopName: 'Stop 8',
      dropOffTime: '03:45 PM', status: 'boarded',
    );
    _activeTrip = const TripModel(
      id: 't1', routeName: 'Route North',
      busNumber: 'B-42', status: 'active',
      estimatedArrival: '8 minutes',
      currentStop: 'Stop 8', totalStops: 12,
      currentStopNumber: 8, pickupTime: '07:30 AM',
      dropOffTime: '03:45 PM', pickupCompleted: true,
    );
    _notifications = const [
      NotificationModel(
        id: 'n1',
        message: 'Bus is 10 minutes away',
        timeAgo: '2 min ago', type: 'info',
      ),
      NotificationModel(
        id: 'n2',
        message: 'Emma boarded the bus',
        timeAgo: '25 min ago', type: 'success',
      ),
      NotificationModel(
        id: 'n3',
        message: 'Slight delay due to traffic',
        timeAgo: '1 hour ago', type: 'warning',
      ),
    ];
  }

  void _loadDriverData() {
    _currentUser = const UserModel(
      id: '2', name: 'John Davis',
      email: 'driver@school.edu', role: 'driver',
    );
    _students = const [
      StudentModel(id: 's1', name: 'Emma Johnson', grade: 'Grade 5', stopName: 'Stop 4', dropOffTime: '03:45 PM', status: 'pending'),
      StudentModel(id: 's2', name: 'Liam Smith', grade: 'Grade 6', stopName: 'Stop 4', dropOffTime: '03:45 PM', status: 'pending'),
      StudentModel(id: 's3', name: 'Olivia Brown', grade: 'Grade 4', stopName: 'Stop 5', dropOffTime: '03:52 PM', status: 'pending'),
      StudentModel(id: 's4', name: 'Noah Davis', grade: 'Grade 5', stopName: 'Stop 5', dropOffTime: '03:52 PM', status: 'absent'),
      StudentModel(id: 's5', name: 'Ava Wilson', grade: 'Grade 7', stopName: 'Stop 6', dropOffTime: '03:58 PM', status: 'pending'),
      StudentModel(id: 's6', name: 'Ethan Martinez', grade: 'Grade 5', stopName: 'Stop 6', dropOffTime: '03:58 PM', status: 'pending'),
    ];
  }

  void _loadAdminData() {
    _currentUser = const UserModel(
      id: '3', name: 'Admin',
      email: 'admin@school.edu', role: 'admin',
    );
    _buses = const [
      BusModel(id: 'b1', busNumber: 'B-42', routeName: 'Route North', driverName: 'John Davis', totalStudents: 24, studentsOnBoard: 24, routeProgress: 0.67, status: 'active'),
      BusModel(id: 'b2', busNumber: 'B-38', routeName: 'Route East', driverName: 'Sarah Miller', totalStudents: 28, studentsOnBoard: 20, routeProgress: 0.45, status: 'active'),
      BusModel(id: 'b3', busNumber: 'B-51', routeName: 'Route South', driverName: 'Mike Johnson', totalStudents: 22, studentsOnBoard: 10, routeProgress: 0.30, status: 'delayed'),
      BusModel(id: 'b4', busNumber: 'B-29', routeName: 'Route West', driverName: 'Emily Brown', totalStudents: 26, studentsOnBoard: 26, routeProgress: 1.0, status: 'completed'),
      BusModel(id: 'b5', busNumber: 'B-15', routeName: 'Route Central', driverName: 'David Wilson', totalStudents: 0, studentsOnBoard: 0, routeProgress: 0.0, status: 'idle'),
    ];
    _totalStudentsOnBoard = 74;
    _activeAlerts = 1;
    _completedTrips = 1;
    _activeRoutes = 5;
    _onTimeRate = 98.0;
  }

  // ── Driver actions ─────────────────────────────────────────
  void toggleTrip() {
    _tripStarted = !_tripStarted;
    notifyListeners();
  }

  void updateStudentStatus(String studentId, String newStatus) {
    _students = _students.map((s) {
      if (s.id == studentId) {
        return StudentModel(
          id: s.id, name: s.name, grade: s.grade,
          stopName: s.stopName, dropOffTime: s.dropOffTime,
          status: newStatus,
        );
      }
      return s;
    }).toList();
    notifyListeners();
  }
}