class BusModel {
  final String id;
  final String busNumber;
  final String routeName;
  final String driverName;
  final int totalStudents;
  final int studentsOnBoard;
  final double routeProgress; // 0.0 to 1.0
  final String status; // 'active', 'idle', 'delayed', 'completed'

  const BusModel({
    required this.id,
    required this.busNumber,
    required this.routeName,
    required this.driverName,
    required this.totalStudents,
    required this.studentsOnBoard,
    required this.routeProgress,
    required this.status,
  });

  factory BusModel.fromAdminTrip(Map<String, dynamic> json) {
    final bus = (json['bus'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final driver = (json['driver'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final driverUser = (driver['user'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final countMap = (json['_count'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final attendanceCount = (countMap['attendances'] as num?)?.toInt() ?? 0;

    return BusModel(
      id: (json['id'] ?? '').toString(),
      busNumber: (bus['plateNumber'] ?? '--').toString(),
      routeName: (bus['routeName'] ?? '--').toString(),
      driverName: (driverUser['fullName'] ?? 'Unassigned').toString(),
      totalStudents: attendanceCount,
      studentsOnBoard: attendanceCount,
      routeProgress: 0,
      status: _statusFromTrip((json['status'] ?? '').toString()),
    );
  }

  static String _statusFromTrip(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return 'active';
      case 'COMPLETED':
        return 'completed';
      case 'CANCELLED':
        return 'idle';
      case 'SCHEDULED':
      default:
        return 'idle';
    }
  }
}
