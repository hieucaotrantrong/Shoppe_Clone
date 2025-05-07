import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL cơ sở của API
  static final String baseUrl = 'http://localhost:3001/api';
  
  // Đăng nhập
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Login failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  // Lấy thông tin người dùng
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Get user info failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
  
  // Đăng ký
  static Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Registration failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }
  
  // Lấy danh sách món ăn
  static Future<List<Map<String, dynamic>>> getFoodItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/food-items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        print('Failed to load food items: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting food items: $e');
      return [];
    }
  }
  
  // Tạo đơn hàng mới
  static Future<Map<String, dynamic>?> createOrder(
    int userId, 
    double totalAmount, 
    List<Map<String, dynamic>> items
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'total_amount': totalAmount,
          'items': items,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Order creation failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Thay đổi mật khẩu
  static Future<Map<String, dynamic>?> changePassword(
      String userId, String currentPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Change password failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error changing password: $e');
      return null;
    }
  }
}



