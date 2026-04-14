import '../api/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get('/notifications') as List<dynamic>;
    return response
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _apiClient.patch('/notifications/$id/read');
  }

  Future<int> getUnreadCount() async {
    final response =
        await _apiClient.get('/notifications/unread-count') as Map<String, dynamic>;
    return (response['unreadCount'] as num?)?.toInt() ?? 0;
  }
}
