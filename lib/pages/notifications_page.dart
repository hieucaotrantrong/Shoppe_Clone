import 'package:flutter/material.dart';
import 'package:food_app/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Tải thông báo khi trang được mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: const Color(0xFFff5722),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .fetchNotifications();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(child: Text('Không có thông báo nào'));
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              final isRead = notification['is_read'] == 1;
              final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
              final createdAt = DateTime.parse(notification['created_at']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                color: isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  title: Text(
                    notification['title'] ?? 'Không có tiêu đề',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(notification['message'] ?? 'Không có nội dung'),
                      const SizedBox(height: 5),
                      Text(
                        dateFormat.format(createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      provider.markAsRead(notification['id'].toString());
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
