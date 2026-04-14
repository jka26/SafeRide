import 'trip_model.dart';

class StudentSearchResult {
  final String id;
  final String studentCode;
  final String fullName;
  final String grade;
  final String? routeName;
  final String? busLabel;

  const StudentSearchResult({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.grade,
    this.routeName,
    this.busLabel,
  });

  factory StudentSearchResult.fromJson(Map<String, dynamic> json) {
    return StudentSearchResult(
      id: json['id'] as String,
      studentCode: json['studentCode'] as String,
      fullName: json['fullName'] as String,
      grade: json['grade'] as String,
      routeName: json['routeName'] as String?,
      busLabel: json['busLabel'] as String?,
    );
  }
}

class StudentModel {
  final String id;
  final String name;
  final String grade;
  final String? stopId;
  final String? stopName;
  final String? dropOffTime;
  final String status; // 'pending', 'boarded', 'alighted', 'absent'
  final TripModel? latestTrip;

  const StudentModel({
    required this.id,
    required this.name,
    required this.grade,
    this.stopId,
    this.stopName,
    this.dropOffTime,
    this.status = 'pending',
    this.latestTrip,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory StudentModel.fromParentDashboard(Map<String, dynamic> json) {
    final latestAttendance = json['latestAttendance'] as Map<String, dynamic>?;
    final activeTrip = json['activeTrip'] as Map<String, dynamic>?;
    return StudentModel(
      id: (json['id'] ?? '').toString(),
      name: (json['fullName'] ?? '').toString(),
      grade: (json['grade'] ?? '').toString(),
      stopName: (json['stopName'] as String?)?.trim(),
      dropOffTime: (json['dropOffTime'] as String?)?.trim(),
      status: _statusFromAttendance(latestAttendance?['status']),
      latestTrip: activeTrip != null
          ? TripModel.fromParentActiveTrip(activeTrip)
          : (latestAttendance == null
              ? null
              : TripModel.fromParentAttendance(latestAttendance)),
    );
  }

  factory StudentModel.fromDriverAttendance(Map<String, dynamic> json) {
    final student = (json['student'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    return StudentModel(
      id: (student['id'] ?? '').toString(),
      name: (student['fullName'] ?? '').toString(),
      grade: (student['grade'] ?? '').toString(),
      status: _statusFromAttendance(json['status']),
    );
  }

  factory StudentModel.fromBusRoster(Map<String, dynamic> json) {
    return StudentModel(
      id: (json['id'] ?? '').toString(),
      name: (json['fullName'] ?? '').toString(),
      grade: (json['grade'] ?? '').toString(),
      stopName: (json['stopName'] ?? '').toString(),
      dropOffTime: (json['dropOffTime'] ?? '').toString(),
      status: _statusFromAttendance(json['attendanceStatus']),
    );
  }

  static String _statusFromAttendance(dynamic status) {
    switch ((status ?? '').toString().toUpperCase()) {
      case 'PRESENT':
      case 'BOARDED':
        return 'boarded';
      case 'ALIGHTED':
        return 'alighted';
      case 'ABSENT':
        return 'absent';
      default:
        return 'pending';
    }
  }
}
