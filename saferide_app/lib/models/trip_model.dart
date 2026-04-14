class TripModel {
  final String id;
  final String routeName;
  final String busNumber;
  final String status; // 'idle', 'active', 'completed', 'cancelled'
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
    final etaMinutes = (json['etaMinutes'] as num?)?.toInt();
    final backendStatus = (json['status'] ?? '').toString();
    return TripModel(
      id: (json['id'] ?? '').toString(),
      routeName: (bus['routeName'] ?? json['name'] ?? '--').toString(),
      busNumber: (bus['plateNumber'] ?? '--').toString(),
      status: _uiStatusFromTripStatus(backendStatus),
      estimatedArrival: etaMinutes == null ? null : '$etaMinutes min',
      currentStop: (json['currentStopName'] as String?)?.trim(),
      totalStops: ((json['attendances'] as List<dynamic>?) ?? const []).length,
      currentStopNumber: 0,
      pickupTime: tripDate?.toLocal().toString(),
      dropOffTime: null,
      pickupCompleted: backendStatus.toUpperCase() == 'COMPLETED',
    );
  }

  factory TripModel.fromParentAttendance(Map<String, dynamic> json) {
    final trip = (json['trip'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final bus = (trip['bus'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final tripDate = DateTime.tryParse((trip['tripDate'] ?? '').toString());
    final attendanceStatus = (json['status'] ?? '').toString().toUpperCase();
    final tripStatus = (trip['status'] ?? '').toString();
    return TripModel(
      id: (trip['id'] ?? '').toString(),
      routeName: (trip['name'] ?? bus['routeName'] ?? '--').toString(),
      busNumber: (bus['plateNumber'] ?? '--').toString(),
      status: _uiStatusFromTripStatus(tripStatus),
      estimatedArrival: null,
      currentStop: (trip['currentStopName'] as String?)?.trim(),
      totalStops: 0,
      currentStopNumber: 0,
      pickupTime: tripDate?.toLocal().toString(),
      dropOffTime: null,
      pickupCompleted: attendanceStatus == 'PRESENT' ||
          attendanceStatus == 'BOARDED' ||
          attendanceStatus == 'ALIGHTED',
    );
  }

  factory TripModel.fromParentActiveTrip(Map<String, dynamic> json) {
    final bus = (json['bus'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final latestLocation = (json['latestLocation'] ?? const <String, dynamic>{})
        as Map<String, dynamic>;
    final locationSeen = latestLocation.isNotEmpty;
    return TripModel(
      id: (json['tripId'] ?? json['id'] ?? '').toString(),
      routeName: (json['name'] ?? bus['routeName'] ?? '--').toString(),
      busNumber: (bus['plateNumber'] ?? '--').toString(),
      status: _uiStatusFromTripStatus((json['status'] ?? '').toString()),
      estimatedArrival: (json['etaMinutes'] as num?) == null
          ? null
          : '${(json['etaMinutes'] as num).toInt()} min',
      currentStop: (json['currentStopName'] as String?)?.trim(),
      totalStops: locationSeen ? 1 : 0,
      currentStopNumber: locationSeen ? 1 : 0,
      pickupTime: null,
      dropOffTime: null,
      pickupCompleted: false,
    );
  }

  static String _uiStatusFromTripStatus(String backendStatus) {
    switch (backendStatus.toUpperCase()) {
      case 'IN_PROGRESS':
        return 'active';
      case 'COMPLETED':
        return 'completed';
      case 'CANCELLED':
        return 'cancelled';
      case 'SCHEDULED':
      default:
        return 'idle';
    }
  }
}
