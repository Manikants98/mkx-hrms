import 'package:flutter/material.dart';
import '../data/notifications_repository.dart';
import '../models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationsRepository _repo = NotificationsRepository();

  List<NotificationRecord> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationRecord> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repo.getNotifications();
      _notifications = data.notifications;
      _unreadCount = data.unreadCount;
    } catch (e) {
      _errorMessage = 'Failed to load notifications.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id, bool isCurrentlyRead) async {
    if (isCurrentlyRead) return;

    try {
      final success = await _repo.markAsRead(id);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignore errors for individual read updates
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _repo.markAllAsRead();
      if (success) {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
