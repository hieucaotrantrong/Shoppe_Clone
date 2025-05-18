import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:food_app/pages/home.dart';
import 'package:food_app/pages/order.dart';
import 'package:food_app/pages/profile.dart';
import 'package:food_app/pages/notifications_page.dart';
import 'package:food_app/pages/chat_page.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({Key? key}) : super(key: key);

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    // Cập nhật danh sách trang - xóa trang ChatPage
    final List<Widget> pages = [
      const Home(),
      Order(cartItems: cartProvider.cartItems),
      const NotificationsPage(),
      const Profile(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60,
        backgroundColor: Color(0xFFff5722),
        color: const Color.fromARGB(255, 239, 178, 159),
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          if (index == 1) {
            // Giả sử index 1 là giỏ hàng
            // Lấy danh sách sản phẩm từ CartProvider
            final cartItems =
                Provider.of<CartProvider>(context, listen: false).cartItems;

            // Chuyển đến trang Order và truyền danh sách sản phẩm
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Order(cartItems: cartItems),
              ),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: [
          const Icon(Icons.home, size: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_cart, size: 30),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications, size: 30),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${notificationProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const Icon(Icons.person, size: 30),
        ],
      ),
    );
  }
}
