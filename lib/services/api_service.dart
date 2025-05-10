import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, File;

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
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      print('Attempting to login with URL: $baseUrl/users/login'); // Debug log

      final response = await http
          .post(
            Uri.parse('$baseUrl/users/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(requestTimeout);

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

  // Phương thức đầu tiên - đổi tên thành getProductsData
  static Future<Map<String, dynamic>?> getProductsData() async {
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

  // Phương thức thứ hai - giữ nguyên tên getProducts
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        print('Failed to load products: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  // Tạo đơn hàng mới
  static Future<Map<String, dynamic>?> createOrder(
      int userId, double totalAmount, List<Map<String, dynamic>> items) async {
    try {
      // Đảm bảo mỗi item có đủ thông tin, đặc biệt là name
      final formattedItems = items
          .map((item) => {
                'product_id': int.tryParse(item['id'].toString()) ?? 0,
                'name': item['name'] ?? 'Sản phẩm không xác định',
                'quantity': item['quantity'] ?? 1,
                'price': double.tryParse(item['price'].toString()) ?? 0.0
              })
          .toList();

      print('Formatted items for order: ${json.encode(formattedItems)}');

      final requestBody = {
        'user_id': userId,
        'total_amount': totalAmount,
        'items': formattedItems,
      };

      print('Order request body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/orders'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 201) {
        print('Order created successfully: ${response.body}');
        return json.decode(response.body);
      } else {
        print('Failed to create order: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Thêm sản phẩm mới
  static Future<Map<String, dynamic>?> createProduct(
      Map<String, dynamic> productData) async {
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

  // Cập nhật sản phẩm - đảm bảo tham số id là String
  static Future<Map<String, dynamic>?> updateProduct(
      String id, Map<String, dynamic> productData) async {
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

  // Xóa sản phẩm - đảm bảo tham số id là String
  static Future<Map<String, dynamic>?> deleteProduct(String id) async {
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
      print('Fetching all orders from API...');
      final response =
          await http.get(Uri.parse('$baseUrl/orders')).timeout(requestTimeout);

      print('Orders API response status: ${response.statusCode}');
      print('Orders API response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          // Chuyển đổi dữ liệu thành List<Map<String, dynamic>>
          final List<dynamic> rawOrders = data['data'];
          final orders = rawOrders.map((order) {
            // Đảm bảo mỗi đơn hàng là Map<String, dynamic>
            final Map<String, dynamic> orderMap =
                Map<String, dynamic>.from(order);

            // Đảm bảo items là List<Map<String, dynamic>>
            if (orderMap['items'] != null) {
              final List<dynamic> rawItems = orderMap['items'];
              orderMap['items'] = rawItems
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            } else {
              orderMap['items'] = [];
            }

            return orderMap;
          }).toList();

          print('Successfully parsed ${orders.length} orders');
          return orders;
        } else {
          print('API returned success but no data or wrong format');
          return [];
        }
      } else {
        print('API returned error status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  // Cập nhật trạng thái đơn hàng
  static Future<Map<String, dynamic>?> updateOrderStatus(
      String orderId, String status) async {
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
  static Future<List<Map<String, dynamic>>> getProductsList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        print('Failed to load products: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  // Lấy tất cả người dùng (cho admin)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('Fetching all users from API...');
      final response =
          await http.get(Uri.parse('$baseUrl/users')).timeout(requestTimeout);

      print('Users API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> rawUsers = data['data'];
          final users =
              rawUsers.map((user) => Map<String, dynamic>.from(user)).toList();

          print('Successfully parsed ${users.length} users');
          return users;
        } else {
          print('API returned success but no data or wrong format');
          return [];
        }
      } else {
        print('API returned error status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Tạo người dùng mới (cho admin)
  static Future<Map<String, dynamic>?> createUser(
      String name, String email, String password, String role) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('User creation failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  // Cập nhật người dùng (cho admin)
  static Future<Map<String, dynamic>?> updateUser(
      String userId, String name, String email, String? password, String role,
      {String? profileImage}) async {
    try {
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'role': role,
      };

      // Chỉ thêm mật khẩu nếu được cung cấp
      if (password != null && password.isNotEmpty) {
        userData['password'] = password;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('User update failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }

  // Xóa người dùng (cho admin)
  static Future<Map<String, dynamic>?> deleteUser(String userId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/users/$userId'),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('User deletion failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error deleting user: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getFilteredProducts(
      {String? category, String? searchQuery}) async {
    try {
      final Uri uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: {
          if (category != null && category != 'All') 'category': category,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'search': searchQuery,
        },
      );

      print("Fetching products from: $uri");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API response: $data");

        if (data['status'] == 'success') {
          final List<dynamic> productsJson = data['data'];
          final products =
              productsJson.map((json) => json as Map<String, dynamic>).toList();
          return products;
        } else {
          print('API returned error: ${data['message']}');
          return [];
        }
      } else {
        print('Failed to load products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in getFilteredProducts: $e');
      return [];
    }
  }

  // Upload ảnh đại diện
  static Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Tạo request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-image'),
      );
      
      // Thêm file ảnh vào request
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      // Thêm userId vào request
      request.fields['user_id'] = userId;
      
      print('Sending profile image upload request to: ${request.url}');
      print('With user ID: $userId');
      print('Image path: ${imageFile.path}');
      
      // Gửi request
      var streamedResponse = await request.send().timeout(requestTimeout);
      
      // Đọc response
      var response = await http.Response.fromStream(streamedResponse);
      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');
      
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          print('Upload successful: ${jsonData['image_url']}');
          return jsonData['image_url'];
        } else {
          print('Upload failed: ${jsonData['message']}');
          return null;
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Cập nhật thông tin cá nhân (cho người dùng)
  static Future<Map<String, dynamic>?> updateUserProfile(
    String userId,
    String name,
    String email,
    String? password, {
    String? profileImage,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
      };

      // Chỉ thêm mật khẩu nếu được cung cấp
      if (password != null && password.isNotEmpty) {
        userData['password'] = password;
      }

      // Thêm ảnh đại diện nếu được cung cấp
      if (profileImage != null) {
        userData['profile_image'] = profileImage;
      }

      // Sử dụng endpoint /api/users/:id thay vì /api/users/profile/:id
      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Profile update failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }
}







