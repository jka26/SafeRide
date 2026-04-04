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
}