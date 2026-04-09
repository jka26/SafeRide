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
    return StudentModel(
      id: (json['id'] ?? '').toString(),
      name: (json['fullName'] ?? '').toString(),
      grade: (json['grade'] ?? '').toString(),
      status: _statusFromAttendance(latestAttendance?['status']),
      latestTrip: latestAttendance == null
          ? null
          : TripModel.fromParentAttendance(latestAttendance),
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

  static String _statusFromAttendance(dynamic status) {
    switch ((status ?? '').toString().toUpperCase()) {
      case 'PRESENT':
        return 'boarded';
      case 'ABSENT':
        return 'absent';
      default:
        return 'pending';
    }
  }
}
