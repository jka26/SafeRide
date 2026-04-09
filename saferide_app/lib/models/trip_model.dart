class TripModel {
  final String id;
  final String routeName;
  final String busNumber;
  final String status; // 'idle', 'active', 'completed'
  final String? estimatedArrival;
  final String? currentStop;
  final int totalStops;
  final int currentStopNumber;
  final String? pickupTime;
  final String? dropOffTime;
  final bool pickupCompleted;

  const TripModel({
    required this.id,
    required this.routeName,
    required this.busNumber,
    required this.status,
    this.estimatedArrival,
    this.currentStop,
    required this.totalStops,
    required this.currentStopNumber,
    this.pickupTime,
    this.dropOffTime,
    this.pickupCompleted = false,
  });

  factory TripModel.fromDriverDashboard(Map<String, dynamic> json) {
    final bus = (json['bus'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final tripDate = DateTime.tryParse((json['tripDate'] ?? '').toString());
    return TripModel(
      id: (json['id'] ?? '').toString(),
      routeName: (bus['routeName'] ?? json['name'] ?? '--').toString(),
      busNumber: (bus['plateNumber'] ?? '--').toString(),
      status: 'active',
      estimatedArrival: null,
      currentStop: null,
      totalStops: ((json['attendances'] as List<dynamic>?) ?? const []).length,
      currentStopNumber: 0,
      pickupTime: tripDate?.toLocal().toString(),
      dropOffTime: null,
      pickupCompleted: false,
    );
  }

  factory TripModel.fromParentAttendance(Map<String, dynamic> json) {
    final trip = (json['trip'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final bus = (trip['bus'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final tripDate = DateTime.tryParse((trip['tripDate'] ?? '').toString());
    return TripModel(
      id: (trip['id'] ?? '').toString(),
      routeName: (trip['name'] ?? bus['routeName'] ?? '--').toString(),
      busNumber: (bus['plateNumber'] ?? '--').toString(),
      status: (json['status'] ?? 'idle').toString().toLowerCase(),
      estimatedArrival: null,
      currentStop: null,
      totalStops: 0,
      currentStopNumber: 0,
      pickupTime: tripDate?.toLocal().toString(),
      dropOffTime: null,
      pickupCompleted: (json['status'] ?? '') == 'PRESENT',
    );
  }
}
