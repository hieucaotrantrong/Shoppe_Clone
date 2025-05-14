import 'package:flutter/foundation.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';

class NotificationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _userId;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final userId = await SharedPreferenceHelper().getUserId();
    if (userId != null) {
      _userId = userId;
      await fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    if (_userId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final notifications = await ApiService.getUserNotifications(_userId!);
      _notifications = notifications;
      _updateUnreadCount();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await ApiService.markNotificationAsRead(notificationId);
      if (success) {
        final index = _notifications.indexWhere((n) => n['id'].toString() == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = 1;
          _updateUnreadCount();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => n['is_read'] == 0).length;
  }
}