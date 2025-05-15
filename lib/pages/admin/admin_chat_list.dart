import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'admin_chat_detail.dart';

class AdminChatList extends StatefulWidget {
  const AdminChatList({Key? key}) : super(key: key);

  @override
  State<AdminChatList> createState() => _AdminChatListState();
}

class _AdminChatListState extends State<AdminChatList> {
  List<Map<String, dynamic>> _chatUsers = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
    
    // Tự động làm mới danh sách mỗi 5 giây
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadChatUsers();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChatUsers() async {
    try {
      final users = await ApiService.getChatUsers();
      
      setState(() {
        _chatUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn khách hàng'),
        backgroundColor: const Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatUsers.isEmpty
              ? const Center(child: Text('Chưa có cuộc trò chuyện nào.'))
              : ListView.builder(
                  itemCount: _chatUsers.length,
                  itemBuilder: (context, index) {
                    final user = _chatUsers[index];
                    final hasUnread = (user['unread_count'] ?? 0) > 0;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFff5722),
                        child: Text(
                          (user['user_name'] ?? 'User').substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        user['user_name'] ?? 'Người dùng ${user['user_id']}',
                        style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        user['last_message'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDateTime(user['last_message_time']),
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                user['unread_count'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminChatDetail(
                              userId: user['user_id'],
                              userName: user['user_name'] ?? 'Người dùng ${user['user_id']}',
                            ),
                          ),
                        ).then((_) => _loadChatUsers());
                      },
                    );
                  },
                ),
    );
  }
}