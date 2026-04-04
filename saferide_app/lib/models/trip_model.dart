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
}