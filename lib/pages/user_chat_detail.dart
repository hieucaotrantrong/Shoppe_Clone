import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class UserChatDetail extends StatefulWidget {
  final String userId;
  final String userName;

  const UserChatDetail({Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  State<UserChatDetail> createState() => _UserChatDetailState();
}

class _UserChatDetailState extends State<UserChatDetail> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  DateTime _lastRefreshTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    
    // Đánh dấu tin nhắn là đã đọc khi mở trang chat
    _markMessagesAsRead();
    
    // Tự động làm mới tin nhắn mỗi 1 giây
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi ứng dụng được mở lại, cập nhật ngay lập tức
      _loadMessages();
      _markMessagesAsRead();
    }
  }

  Future<void> _loadMessages() async {
    try {
      // Chỉ làm mới nếu đã qua ít nhất 500ms kể từ lần cuối
      final now = DateTime.now();
      if (now.difference(_lastRefreshTime).inMilliseconds < 500) {
        return;
      }
      _lastRefreshTime = now;
      
      print('Loading messages for user: ${widget.userId}');
      final messages = await ApiService.getChatMessages(widget.userId);
      print('Received ${messages.length} messages');

      // Kiểm tra xem có tin nhắn mới không
      bool hasNewMessages = false;
      if (_messages.length != messages.length) {
        hasNewMessages = true;
        print('New messages detected: ${messages.length} vs ${_messages.length}');
      } else if (_messages.isNotEmpty && messages.isNotEmpty) {
        // Kiểm tra ID tin nhắn cuối cùng
        final lastOldMsgId = _messages.last['id'];
        final lastNewMsgId = messages.last['id'];
        if (lastOldMsgId != lastNewMsgId) {
          hasNewMessages = true;
          print('New message ID detected: $lastNewMsgId vs $lastOldMsgId');
        }
      }

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }

      // Đánh dấu tin nhắn từ admin là đã đọc
      if (hasNewMessages) {
        print('Marking messages as read');
        await ApiService.markMessagesAsRead(widget.userId, 'admin');
        
        // Cuộn xuống tin nhắn cuối cùng nếu có tin nhắn mới
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Thêm tin nhắn vào danh sách local trước
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': widget.userId,
      'sender': 'user',
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false
    };

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    try {
      // Gửi tin nhắn lên server
      final success =
          await ApiService.sendChatMessage(widget.userId, message, 'user');

      if (!success) {
        print('Failed to send message to server');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
        );
      } else {
        print('Message sent successfully');
        // Tải lại tin nhắn để cập nhật ID chính xác từ server
        _loadMessages();
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi tin nhắn: $e')),
      );
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

  Future<void> _markMessagesAsRead() async {
    try {
      await ApiService.markMessagesAsRead(widget.userId, 'admin');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hỗ trợ khách hàng'),
        backgroundColor: const Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                            'Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện!'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message['sender'] == 'user';

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFFff5722)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message'],
                                    style: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(message['created_at']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isUser
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFff5722)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




