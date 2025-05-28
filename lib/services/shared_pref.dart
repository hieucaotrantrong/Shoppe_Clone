import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const String userIdKey = 'userId';
  static const String userNameKey = 'userName';
  static const String userEmailKey = 'userEmail';
  static const String userRoleKey = 'userRole';
  static const String userProfileKey = 'userProfile';

  // Lưu thông tin người dùng
  Future<bool> saveUserData(
      String userId, String userName, String userEmail, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userId);
    await prefs.setString(userNameKey, userName);
    await prefs.setString(userEmailKey, userEmail);
    await prefs.setString(userRoleKey, role);

    return true;
  }

  // Lấy thông tin người dùng
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey);

    return userId;
  }

  // Lấy tên người dùng
  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  // Lấy email người dùng
  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  // Lấy vai trò người dùng
  Future<String?> getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userRoleKey);
  }

  // Kiểm tra người dùng đã đăng nhập chưa
  Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userIdKey);
  }

  // Kiểm tra người dùng có phải admin không
  Future<bool> isAdmin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString(userRoleKey);
    return role == 'admin';
  }

  // Xóa thông tin người dùng khi đăng xuất
  Future<bool> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userRoleKey);
    return true;
  }

  // Lưu URL ảnh đại diện người dùng
  Future<bool> saveUserProfile(String profileUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userProfileKey, profileUrl);
  }

  // Lấy URL ảnh đại diện người dùng
  Future<String?> getUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userProfileKey);
  }
}
