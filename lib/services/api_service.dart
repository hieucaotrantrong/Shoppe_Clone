import 'dart:convert';
import 'dart:io';
import 'dart:math'; // Thêm import này cho hàm min
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Cập nhật baseUrl để không có "api/" ở cuối
  static const String baseUrl = 'http://localhost:3001/api';
  static const Duration requestTimeout = Duration(seconds: 10);

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
      String orderId, String status, {String? reason}) async {
    try {
      final url = '$baseUrl/orders/$orderId/status';
      print('Calling API: $url');
      
      // Tạo body request với lý do nếu có
      final Map<String, dynamic> requestBody = {
        'status': status,
      };
      
      // Thêm lý do nếu có
      if (reason != null && reason.isNotEmpty) {
        requestBody['reason'] = reason;
      }
      
      final response = await http
          .put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to update order status: ${response.statusCode}');
        print('Response body: ${response.body}');
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

  // Kiểm tra xem ứng dụng đang chạy trên web hay không
  static bool get isWeb => kIsWeb;

  // Upload ảnh đại diện (phiên bản web)
  static Future<String?> uploadProfileImageWeb(
      String userId, Uint8List imageBytes, String fileName) async {
    try {
      print("Starting web profile image upload for user ID: $userId");
      print("Image file name: $fileName");
      print("Image size: ${imageBytes.length} bytes");

      // Tạo request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-image'),
      );

      // Thêm file ảnh vào request (dạng bytes cho web)
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', fileName.split('.').last),
      );
      request.files.add(multipartFile);

      // Thêm userId vào request
      request.fields['user_id'] = userId;

      print('Sending web profile image upload request to: ${request.url}');

      // Gửi request
      var streamedResponse = await request.send().timeout(Duration(minutes: 2));

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
      print('Error uploading profile image on web: $e');
      return null;
    }
  }

  // Upload ảnh đại diện
  static Future<String?> uploadProfileImage(
      String userId, File imageFile) async {
    try {
      // Kiểm tra xem file có tồn tại không
      if (!await imageFile.exists()) {
        print("Image file does not exist: ${imageFile.path}");
        return null;
      }

      print("Starting profile image upload for user ID: $userId");
      print("Image file path: ${imageFile.path}");
      print("Image file size: ${await imageFile.length()} bytes");

      // Tạo request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-image'),
      );

      // Thêm file ảnh vào request
      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      );
      request.files.add(multipartFile);

      // Thêm userId vào request
      request.fields['user_id'] = userId;

      print('Sending profile image upload request to: ${request.url}');
      print('With user ID: $userId');
      print('Image file name: ${multipartFile.filename}');
      print('Image content type: ${multipartFile.contentType}');

      // Gửi request với timeout dài hơn cho upload file
      var streamedResponse = await request.send().timeout(Duration(minutes: 2));

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

  // Lấy thông báo của người dùng
  static Future<List<Map<String, dynamic>>> getUserNotifications(
      String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/$userId/notifications'))
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> notificationsJson = data['data'];
          return notificationsJson
              .map((json) => json as Map<String, dynamic>)
              .toList();
        } else {
          print('API returned error: ${data['message']}');
          return [];
        }
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Đánh dấu thông báo đã đọc
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await http
          .put(Uri.parse('$baseUrl/notifications/$notificationId/read'))
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to mark notification as read: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Lấy tin nhắn chat của người dùng
  static Future<List<Map<String, dynamic>>> getChatMessages(
      String userId) async {
    try {
      // Thêm timestamp để tránh cache hoàn toàn
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/chat/messages/$userId?t=$timestamp'),
        headers: {'Cache-Control': 'no-cache, no-store, must-revalidate'},
      ).timeout(requestTimeout);

      print(
          'API response for messages: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final messages = List<Map<String, dynamic>>.from(data['data']);
          print('Retrieved ${messages.length} messages for user $userId');
          return messages;
        }
      }
      return [];
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  // Gửi tin nhắn chat
  static Future<bool> sendChatMessage(
      String userId, String message, String sender) async {
    try {
      print('SENDING MESSAGE:');
      print('- userId: $userId');
      print('- message: $message');
      print('- sender: $sender');

      final url = '$baseUrl/chat/messages';
      print('- url: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(
                {'userId': userId, 'message': message, 'sender': sender}),
          )
          .timeout(requestTimeout);

      print('RESPONSE: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('ERROR SENDING MESSAGE: $e');
      return false;
    }
  }

  // Lấy danh sách người dùng có tin nhắn (cho admin)
  static Future<List<Map<String, dynamic>>> getChatUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/chat/users'))
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error getting chat users: $e');
      return [];
    }
  }

  // Đánh dấu tin nhắn đã đọc
  static Future<bool> markMessagesAsRead(String userId, String sender) async {
    try {
      // Thêm timestamp để tránh cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/mark-read?t=$timestamp'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': userId, 'sender': sender}),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  // Lấy số lượng tin nhắn chưa đọc
  static Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread-count/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Hàm để lấy danh sách đơn hàng của người dùng
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      // Sửa URL để khớp với endpoint của server
      final url = '$baseUrl/orders?user_id=$userId';
      print('Calling API: $url');

      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(requestTimeout);

      print('User orders response status: ${response.statusCode}');
      print(
          'User orders response body: ${response.body.substring(0, min(200, response.body.length))}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        print('Failed to load user orders: ${response.statusCode}');
        print(
            'Response body: ${response.body.substring(0, min(200, response.body.length))}...');
        return [];
      }
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  // Cập nhật hàm để lấy các mục trong đơn hàng - sửa đường dẫn API
  static Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      // Sửa đường dẫn API - bỏ "api/" nếu server không có prefix này
      final response = await http
          .get(
            Uri.parse('$baseUrl/orders/$orderId/items'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(requestTimeout);

      print('Order items response status: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, min(100, response.body.length))}...');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Kiểm tra cấu trúc response
        if (responseData is Map && responseData.containsKey('data')) {
          // Nếu response có dạng {status: success, data: [...]}
          final List<dynamic> items = responseData['data'];
          return items.map((item) => item as Map<String, dynamic>).toList();
        } else if (responseData is List) {
          // Nếu response trực tiếp là một mảng
          return responseData.map((item) => item as Map<String, dynamic>).toList();
        } else {
          // Trường hợp khác
          print('Unexpected response format: ${responseData.runtimeType}');
          return [];
        }
      } else {
        print('Error status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting order items: $e');
      return [];
    }
  }
}




