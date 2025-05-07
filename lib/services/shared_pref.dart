import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey = 'user_role';
  static const String userProfileKey = 'user_profile';

  // Lưu thông tin người dùng
  Future<bool> saveUserData(String userId, String name, String email, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userId);
    await prefs.setString(userNameKey, name);
    await prefs.setString(userEmailKey, email);
    await prefs.setString(userRoleKey, role);
    return true;
  }

  // Lấy ID người dùng
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
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




