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

class _ChatPageState extends State<ChatPage> {
  String? _userId;
  String? _userName;
  bool _isLoading = true;
  List<Map<String, dynamic>> _chatHistory = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      if (_userId != null) {
        _loadChatHistory();
      }
    });

    // Kiểm tra kết nối API
    _checkApiConnection();

    // Tự động làm mới danh sách mỗi 10 giây
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_userId != null) {
        _loadChatHistory();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      _userId = await SharedPreferenceHelper().getUserId();
      _userName = await SharedPreferenceHelper().getUserName();
      
      setState(() {});

      if (_userId == null) {
        print('WARNING: userId is null, user might not be logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng đăng nhập để sử dụng chat')),
        );
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null) return;

    try {
      final messages = await ApiService.getChatMessages(_userId!);
      
      // Tính số tin nhắn chưa đọc từ admin
      int unreadCount = 0;
      String lastMessage = '';
      String lastMessageTime = DateTime.now().toIso8601String();
      
      if (messages.isNotEmpty) {
        lastMessage = messages.last['message'] ?? '';
        lastMessageTime = messages.last['created_at'] ?? DateTime.now().toIso8601String();
        
        for (var msg in messages) {
          if (msg['sender'] == 'admin' && msg['is_read'] == false) {
            unreadCount++;
          }
        }
      }
      
      setState(() {
        _chatHistory = [{
          'user_id': _userId,
          'user_name': _userName ?? 'Bạn',
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'unread_count': unreadCount,
          'has_messages': messages.isNotEmpty
        }];
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

  Future<void> _checkApiConnection() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/health'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối.')),
        );
      }
    } catch (e) {
      print('API connection error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối.')),
      );
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
          : _userId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Vui lòng đăng nhập để sử dụng chat'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Chuyển đến trang đăng nhập
                          // Navigator.pushNamed(context, '/login');
                        },
                        child: Text('Đăng nhập'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFff5722),
                        ),
                      ),
                    ],
                  ),
                )
              : _chatHistory.isEmpty || !_chatHistory[0]['has_messages']
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Bạn chưa có cuộc trò chuyện nào'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Tạo cuộc trò chuyện mới
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
                            child: Text('Bắt đầu trò chuyện'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFff5722),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final chat = _chatHistory[index];
                        final hasUnread = (chat['unread_count'] ?? 0) > 0;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFff5722),
                            child: Icon(Icons.support_agent, color: Colors.white),
                          ),
                          title: Text(
                            'Hỗ trợ khách hàng',
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            chat['last_message'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDateTime(chat['last_message_time']),
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
                                    chat['unread_count'].toString(),
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
                                builder: (context) => UserChatDetail(
                                  userId: _userId!,
                                  userName: _userName ?? 'Bạn',
                                ),
                              ),
                            ).then((_) => _loadChatHistory());
                          },
                        );
                      },
                    ),
    );
  }
}

