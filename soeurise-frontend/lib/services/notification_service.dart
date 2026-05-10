import 'package:flutter/material.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _api = ApiClient.instance;

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Fetch user notifications
  Future<List<dynamic>> getNotifications({int page = 1}) async {
    try {
      final res = await _api.get('/notifications?page=$page');
      if (res.success && res.data != null) {
        return res.data['notifications'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final res = await _api.get('/notifications/unread-count');
      if (res.success && res.data != null) {
        final count = res.data['count'] ?? 0;
        unreadCount.value = count;
        return count;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _api.post('/notifications/$id/read', {});
      if (unreadCount.value > 0) {
        unreadCount.value--;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _api.post('/notifications/mark-all-read', {});
      unreadCount.value = 0;
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // --- UI Messages ---
  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showNotificationSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: const Color(0xFFE8758F), // AppColors.primary
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VOIR',
          textColor: Colors.white,
          onPressed: () {
             // Maybe navigate to notifications
          },
        ),
      ),
    );
  }
}
