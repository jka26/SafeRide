class NotificationModel {
  final String id;
  final String message;
  final String timeAgo;
  final String type; // 'info', 'success', 'warning'

  const NotificationModel({
    required this.id,
    required this.message,
    required this.timeAgo,
    required this.type,
  });
}