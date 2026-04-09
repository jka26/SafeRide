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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString();
    final body = (json['body'] ?? json['message'] ?? '').toString();
    final createdAt = DateTime.tryParse((json['createdAt'] ?? '').toString());

    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      message: title.isEmpty ? body : '$title: $body',
      timeAgo: _timeAgo(createdAt),
      type: _typeFromText('$title $body'),
    );
  }

  static String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Now';
    }
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} hr ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  static String _typeFromText(String text) {
    final value = text.toLowerCase();
    if (value.contains('alert') || value.contains('delay') || value.contains('absent')) {
      return 'warning';
    }
    if (value.contains('present') || value.contains('success')) {
      return 'success';
    }
    return 'info';
  }
}
