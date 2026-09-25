import 'package:mkx_core/constants/api_endpoints.dart';
import 'package:mkx_core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  final DioClient _client = DioClient.instance;

  Future<({List<NotificationRecord> notifications, int unreadCount})> getNotifications() async {
    final response = await _client.get(ApiEndpoints.notifications);
    if (response is Map<String, dynamic>) {
      final list = (response['data']?['notifications'] as List<dynamic>? ?? [])
          .map((item) => NotificationRecord.fromJson(item as Map<String, dynamic>))
          .toList();
      final unreadCount = response['data']?['unread_count'] as int? ?? 0;
      return (notifications: list, unreadCount: unreadCount);
    }
    throw Exception("Invalid response format");
  }

  Future<bool> markAsRead(int id) async {
    final res = await _client.patch(ApiEndpoints.markNotificationRead(id));
    return res is Map<String, dynamic>;
  }

  Future<bool> markAllAsRead() async {
    final res = await _client.patch(ApiEndpoints.markAllNotificationsRead);
    return res is Map<String, dynamic>;
  }
}
