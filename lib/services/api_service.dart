import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiService {
  // Chọn baseUrl phù hợp dựa trên nền tảng
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3001/api'; // Cho web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001/api'; // Cho Android Emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:3001/api'; // Cho iOS simulator
    } else {
      return 'http://localhost:3001/api'; // Mặc định cho các nền tảng khác
    }
  }

  // Thêm timeout cho các request
  static const Duration requestTimeout = Duration(seconds: 15);

  // Đăng ký người dùng mới
  static Future<Map<String, dynamic>?> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
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

  // Đăng nhập với timeout
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print('Attempting to login with URL: $baseUrl/users/login'); // Debug log
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(requestTimeout);

      print('Login response status: ${response.statusCode}'); // Debug log
      
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

  // Lấy danh sách sản phẩm
  static Future<List<Map<String, dynamic>>> getFoodItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching food items: $e');
      return [];
    }
  }

  // Tạo đơn hàng mới
  static Future<Map<String, dynamic>?> createOrder(
      int userId, double totalAmount, List<Map<String, dynamic>> items) async {
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

  // Thêm sản phẩm mới
  static Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Product creation failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating product: $e');
      return null;
    }
  }

  // Cập nhật sản phẩm
  static Future<Map<String, dynamic>?> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Product update failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating product: $e');
      return null;
    }
  }

  // Xóa sản phẩm
  static Future<Map<String, dynamic>?> deleteProduct(dynamic id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Product deletion failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error deleting product: $e');
      return null;
    }
  }

  // Lấy tất cả đơn hàng (cho admin)
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  // Cập nhật trạng thái đơn hàng
  static Future<Map<String, dynamic>?> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Order status update failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating order status: $e');
      return null;
    }
  }

  // Thêm phương thức để lấy danh sách sản phẩm
  static Future<Map<String, dynamic>?> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load products: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting products: $e');
      return null;
    }
  }
}





