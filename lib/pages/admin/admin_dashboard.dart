import 'package:flutter/material.dart';
import 'package:food_app/pages/login.dart';
import 'package:food_app/services/shared_pref.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? adminName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  _loadAdminInfo() async {
    adminName = await SharedPreferenceHelper().getUserName();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: _buildDrawer(context),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, $adminName",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildDashboardCards(),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Color(0xFFff5722),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFFff5722),
                ),
              ),
              SizedBox(height: 10),
              Text(
                adminName ?? "Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.dashboard),
          title: Text('Dashboard'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.fastfood),
          title: Text('Manage Products'),
          onTap: () {
            Navigator.pop(context);
            // Điều hướng đến trang quản lý sản phẩm
          },
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Manage Users'),
          onTap: () {
            Navigator.pop(context);
            // Điều hướng đến trang quản lý người dùng
          },
        ),
        ListTile(
          leading: Icon(Icons.shopping_cart),
          title: Text('Manage Orders'),
          onTap: () {
            Navigator.pop(context);
            // Điều hướng đến trang quản lý đơn hàng
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Logout'),
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildDashboardCard(
          "Products",
          Icons.fastfood,
          Colors.blue,
          () {
            // Điều hướng đến trang quản lý sản phẩm
          },
        ),
        _buildDashboardCard(
          "Users",
          Icons.people,
          Colors.green,
          () {
            // Điều hướng đến trang quản lý người dùng
          },
        ),
        _buildDashboardCard(
          "Orders",
          Icons.shopping_cart,
          Colors.orange,
          () {
            // Điều hướng đến trang quản lý đơn hàng
          },
        ),
        _buildDashboardCard(
          "Reports",
          Icons.bar_chart,
          Colors.purple,
          () {
            // Điều hướng đến trang báo cáo
          },
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    // Xóa thông tin người dùng
    await SharedPreferenceHelper().saveUserId("");
    await SharedPreferenceHelper().saveUserName("");
    await SharedPreferenceHelper().saveUserEmail("");
    await SharedPreferenceHelper().saveUserProfile("");
    await SharedPreferenceHelper().saveUserRole("");

    // Chuyển về trang đăng nhập
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LogIn()),
      (route) => false,
    );
  }
}