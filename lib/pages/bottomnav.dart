import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:food_app/pages/home.dart';
import 'package:food_app/pages/order.dart';
import 'package:food_app/pages/profile.dart';
import 'package:food_app/pages/notifications_page.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

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
        backgroundColor: const Color.fromARGB(255, 235, 238, 176),
        color: const Color.fromARGB(255, 207, 210, 150),
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const Icon(Icons.home, color: Colors.white),
          const Icon(Icons.shopping_cart, color: Colors.white),
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications, color: Colors.white),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      notificationProvider.unreadCount > 9 
                          ? '9+' 
                          : notificationProvider.unreadCount.toString(),
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
          const Icon(Icons.person, color: Colors.white),
        ],
      ),
    );
  }
}

