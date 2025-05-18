import 'package:flutter/material.dart';
import 'package:food_app/pages/order.dart';
import 'package:food_app/pages/chat_page.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class HeaderSection extends StatefulWidget {
  final String? userName;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) handleSearch;
  final CartProvider cartProvider;

  const HeaderSection({
    Key? key,
    required this.userName,
    required this.searchController,
    required this.searchQuery,
    required this.handleSearch,
    required this.cartProvider,
  }) : super(key: key);

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  int _unreadMessageCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkUnreadMessages();

    // Thêm timer để tự động kiểm tra tin nhắn mới mỗi 10 giây
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkUnreadMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUnreadMessages() async {
    final userId = await SharedPreferenceHelper().getUserId();
    if (userId != null) {
      try {
        final messages = await ApiService.getChatMessages(userId);

        int unreadCount = 0;
        for (var msg in messages) {
          if (msg['sender'] == 'admin' && msg['is_read'] == false) {
            unreadCount++;
          }
        }

        if (mounted) {
          setState(() {
            _unreadMessageCount = unreadCount;
          });
        }
      } catch (e) {
        print('Error checking unread messages: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFff5722),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(context),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${widget.userName ?? 'User'}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Chào mừng bạn đến với Shoppe",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        // Nút messenger với thông báo số tin nhắn chưa đọc
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatPage(),
              ),
            ).then((_) {
              _checkUnreadMessages();
            });
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.2), // Đổi màu nền thành trắng trong suốt
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.message_outlined,
                    color: Colors.white, // Đổi màu icon thành trắng
                    size: 28),
              ),
              if (_unreadMessageCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_unreadMessageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.handleSearch,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: "Tìm kiếm",
          hintStyle: TextStyle(color: Colors.red),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    widget.searchController.clear();
                    widget.handleSearch('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}
