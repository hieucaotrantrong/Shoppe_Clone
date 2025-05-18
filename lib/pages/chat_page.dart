import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_chat_detail.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  String? _userId;
  String? _userName;
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getUserInfo();

    // Thêm timer để tự động làm mới danh sách chat mỗi 1 giây
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _loadChatHistory();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi ứng dụng được mở lại, cập nhật ngay lập tức
      _loadChatHistory();
    }
  }

  Future<void> _getUserInfo() async {
    try {
      final userId = await SharedPreferenceHelper().getUserId();
      final userName = await SharedPreferenceHelper().getUserName();

      setState(() {
        _userId = userId;
        _userName = userName;
      });

      await _loadChatHistory();
    } catch (e) {
      print('Error loading user info: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('Loading chat history for user: $_userId');
      final messages = await ApiService.getChatMessages(_userId!);

      // Tính số tin nhắn chưa đọc từ admin
      int unreadCount = 0;
      String lastMessage = '';
      String lastMessageTime = DateTime.now().toIso8601String();

      if (messages.isNotEmpty) {
        lastMessage = messages.last['message'] ?? '';
        lastMessageTime =
            messages.last['created_at'] ?? DateTime.now().toIso8601String();

        for (var msg in messages) {
          if (msg['sender'] == 'admin' && msg['is_read'] == false) {
            unreadCount++;
          }
        }
      }

      print('Unread count: $unreadCount, Last message: $lastMessage');

      setState(() {
        _chatHistory = [
          {
            'user_id': _userId,
            'user_name': _userName ?? 'Bạn',
            'last_message': lastMessage,
            'last_message_time': lastMessageTime,
            'unread_count': unreadCount,
            'has_messages': messages.isNotEmpty
          }
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
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
    } catch (e) {
      return 'Không xác định';
    }
  }

  void _startNewChat() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Không thể bắt đầu cuộc trò chuyện. Vui lòng đăng nhập lại.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Tạo tin nhắn đầu tiên từ người dùng
      final message = "Xin chào, tôi cần hỗ trợ.";
      final success =
          await ApiService.sendChatMessage(_userId!, message, 'user');

      if (success) {
        // Nếu gửi thành công, chuyển đến trang chat chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatDetail(
              userId: _userId!,
              userName: _userName ?? 'Bạn',
            ),
          ),
        ).then((_) => _loadChatHistory());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Không thể bắt đầu cuộc trò chuyện. Vui lòng thử lại sau.')),
        );
      }
    } catch (e) {
      print('Error starting new chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ khách hàng'),
        backgroundColor: const Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 80, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Bạn chưa có cuộc trò chuyện nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _startNewChat();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFff5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Bắt đầu trò chuyện'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = _chatHistory[index];
                    final hasUnread = (chat['unread_count'] ?? 0) > 0;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFff5722),
                          child: Icon(Icons.support_agent, color: Colors.white),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Hỗ trợ khách hàng',
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text(
                              chat['last_message'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDateTime(chat['last_message_time']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${chat['unread_count']}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserChatDetail(
                                userId: _userId!,
                                userName: _userName ?? 'Bạn',
                              ),
                            ),
                          ).then((_) => _loadChatHistory());
                        },
                      ),
                    );
                  },
                ),
    );
  }

  // Thêm getter để lấy số tin nhắn chưa đọc
  int get _unreadMessageCount {
    if (_chatHistory.isEmpty) return 0;
    return _chatHistory[0]['unread_count'] ?? 0;
  }
}
