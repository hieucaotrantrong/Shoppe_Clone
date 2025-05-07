import 'package:flutter/material.dart';
import 'package:food_app/pages/login.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? userId, profile, name, email;

  @override
  void initState() {
    super.initState();
    getProfileData();
  }

  getProfileData() async {
    try {
      userId = await SharedPreferenceHelper().getUserId();
      name = await SharedPreferenceHelper().getUserName();
      email = await SharedPreferenceHelper().getUserEmail();
      profile = await SharedPreferenceHelper().getUserProfile();

      setState(() {});
    } catch (e) {
      print("Error loading user info: $e"); // Debug log
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: profile != null && profile!.isNotEmpty
                  ? NetworkImage(profile!)
                  : AssetImage('images/profile_placeholder.png') as ImageProvider,
            ),
            SizedBox(height: 20),
            Text(
              name ?? "User",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              email ?? "user@example.com",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30),
            buildProfileItem(Icons.person, "Edit Profile", () {
              // Chức năng chỉnh sửa hồ sơ
            }),
            buildProfileItem(Icons.history, "Order History", () {
              // Chuyển đến trang lịch sử đơn hàng
            }),
            buildProfileItem(Icons.settings, "Settings", () {
              // Chuyển đến trang cài đặt
            }),
            buildProfileItem(Icons.help, "Help & Support", () {
              // Chuyển đến trang trợ giúp
            }),
            buildProfileItem(Icons.logout, "Logout", () {
              logout();
            }),
          ],
        ),
      ),
    );
  }

  Widget buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFFff5722)),
            SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  // Hàm xử lý đăng xuất
  logout() async {
    // Xóa tất cả dữ liệu của người dùng từ SharedPreferences
    await SharedPreferenceHelper().clearUserData();

    // Hiển thị thông báo đăng xuất thành công
    Fluttertoast.showToast(
        msg: "Đăng xuất thành công",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);

    // Điều hướng về màn hình đăng nhập
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LogIn()));
  }
}



