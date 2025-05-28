import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3001/api';
  // static const String baseUrl = 'http://10.0.2.2:3001/api';
  // static const String baseUrl = 'http://192.168.88.250:3001/api';
  static const Duration requestTimeout = Duration(seconds: 10);
/*---------------------------------
Đăng ký người dùng mới
-----------------------------------*/

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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
Đăng nhập với timeout
 -----------------------------------*/

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
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
        return null;
      }
    } catch (e) {
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
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
Tạo đơn hàng mới
 -----------------------------------*/

  static Future<Map<String, dynamic>?> createOrder(
    int userId,
    double totalAmount,
    List<Map<String, dynamic>> items, {
    String paymentMethod = 'cod',
    String? address,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'total_amount': totalAmount,
          'items': items,
          'payment_method': paymentMethod,
          'shipping_address': address,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
Thêm sản phẩm mới (cho admin)
-----------------------------------*/

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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
Xóa sản phẩm - đảm bảo tham số id
 là String
-----------------------------------*/

  static Future<Map<String, dynamic>?> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
 Lấy tất cả đơn hàng (cho admin)
-----------------------------------*/

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/orders')).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> rawOrders = data['data'];
          final orders = rawOrders.map((order) {
            final Map<String, dynamic> orderMap =
                Map<String, dynamic>.from(order);

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

          return orders;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
Cập nhật trạng thái đơn hàng
-----------------------------------*/

  static Future<Map<String, dynamic>?> updateOrderStatus(
      String orderId, String status,
      {String? reason}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
Thêm phương thức để lấy danh sách sản phẩm
-----------------------------------*/

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
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
Lấy tất cả người dùng (cho admin)
-----------------------------------*/

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/users')).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> rawUsers = data['data'];
          final users =
              rawUsers.map((user) => Map<String, dynamic>.from(user)).toList();

          return users;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
 Tạo người dùng mới (cho admin)
-----------------------------------*/

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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
  Cập nhật người dùng (cho admin)
-----------------------------------*/

  static Future<Map<String, dynamic>?> updateUser(
      String userId, String name, String email, String? password, String role,
      {String? profileImage}) async {
    try {
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'role': role,
      };

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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
 Xóa người dùng (cho admin)
-----------------------------------*/

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
        return null;
      }
    } catch (e) {
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

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> productsJson = data['data'];
          final products =
              productsJson.map((json) => json as Map<String, dynamic>).toList();
          return products;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
Kiểm tra xem ứng dụng đang chạy 
trên web hay không
-----------------------------------*/

  static bool get isWeb => kIsWeb;

  static Future<String?> uploadProfileImageWeb(
      String userId, Uint8List imageBytes, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-image'),
      );

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', fileName.split('.').last),
      );
      request.files.add(multipartFile);

      request.fields['user_id'] = userId;

      var streamedResponse = await request.send().timeout(Duration(minutes: 2));

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          return jsonData['image_url'];
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
Upload ảnh đại diện 
-----------------------------------*/

  static Future<String?> uploadProfileImage(
      String userId, File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return null;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-image'),
      );

      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      );
      request.files.add(multipartFile);

      request.fields['user_id'] = userId;

      var streamedResponse = await request.send().timeout(Duration(minutes: 2));

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          return jsonData['image_url'];
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
Cập nhật thông tin cá nhân (cho người dùng)
-----------------------------------*/

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

      if (password != null && password.isNotEmpty) {
        userData['password'] = password;
      }

      if (profileImage != null) {
        userData['profile_image'] = profileImage;
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

/*---------------------------------
 Lấy thông báo của người dùng
-----------------------------------*/

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
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
Đánh dấu thông báo đã đọc
-----------------------------------*/

  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await http
          .put(Uri.parse('$baseUrl/notifications/$notificationId/read'))
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

/*---------------------------------
Lấy tin nhắn chat của người dùng
-----------------------------------*/

  static Future<List<Map<String, dynamic>>> getChatMessages(
      String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/chat/messages/$userId?t=$timestamp'),
        headers: {'Cache-Control': 'no-cache, no-store, must-revalidate'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final messages = List<Map<String, dynamic>>.from(data['data']);

          return messages;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
 Gửi tin nhắn chat
 -----------------------------------*/
  static Future<bool> sendChatMessage(
      String userId, String message, String sender) async {
    try {
      final url = '$baseUrl/chat/messages';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(
                {'userId': userId, 'message': message, 'sender': sender}),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

/*---------------------------------
 Lấy danh sách người dùng có tin nhắn (cho admin)
    -----------------------------------*/

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
      return [];
    }
  }

/*---------------------------------
 Đánh dấu tin nhắn đã đọc
-----------------------------------*/

  static Future<bool> markMessagesAsRead(String userId, String sender) async {
    try {
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
      return false;
    }
  }

/*---------------------------------
Lấy số lượng tin nhắn chưa đọc
-----------------------------------*/

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
      return 0;
    }
  }

/*---------------------------------
Hàm để lấy danh sách đơn 
hàng của người dùng
-----------------------------------*/

  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final url = '$baseUrl/orders?user_id=$userId';

      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
Cập nhật hàm để lấy các mục trong đơn hàng
-----------------------------------*/

  static Future<List<Map<String, dynamic>>> getOrderItems(
      String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/items'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final List<dynamic> items = responseData['data'];
          return items.map((item) => item as Map<String, dynamic>).toList();
        } else if (responseData is Map && responseData.containsKey('status')) {
          return [];
        } else if (responseData is List) {
          return responseData
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

/*---------------------------------
Phương thức lấy số dư ví
    -----------------------------------*/

  static Future<Map<String, dynamic>> getWalletBalance(String userId) async {
    try {
      final possibleUrls = [
        '$baseUrl/wallet/$userId',
        '$baseUrl/wallets/$userId',
        '$baseUrl/user/wallet/$userId'
      ];

      for (var url in possibleUrls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data['balance'] is String) {
              data['balance'] = double.parse(data['balance']);
            } else if (data['balance'] is int) {
              data['balance'] = data['balance'].toDouble();
            }

            return data;
          }
        } catch (e) {}
      }

      throw Exception('Failed to load wallet balance');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

/*---------------------------------
 Phương thức lấy lịch sử giao dịch
-----------------------------------*/
  static Future<List<Map<String, dynamic>>> getWalletTransactions(
      String userId) async {
    try {
      final url = '$baseUrl/wallet/transactions/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transactions =
            List<Map<String, dynamic>>.from(data['transactions']);

        for (var transaction in transactions) {
          if (transaction['amount'] is String) {
            transaction['amount'] = double.parse(transaction['amount']);
          } else if (transaction['amount'] is int) {
            transaction['amount'] = transaction['amount'].toDouble();
          }
        }

        return transactions;
      } else {
        throw Exception('Failed to load wallet transactions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

/*---------------------------------
Phương thức tạo yêu cầu nạp tiền
-----------------------------------*/
  static Future<Map<String, dynamic>> createWalletTopUp(
      String userId, double amount, String method) async {
    try {
      final url = '$baseUrl/wallet/topup';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'payment_method': method,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create top-up request');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

/*---------------------------------
Phương thức lấy danh sách yêu cầu
 nạp tiền (cho admin)
-----------------------------------*/

  static Future<List<Map<String, dynamic>>> getWalletTopUpRequests(
      String filter) async {
    try {
      final url = '$baseUrl/admin/wallet/topups?filter=$filter';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final topups = List<Map<String, dynamic>>.from(data['topups']);

        for (var topup in topups) {
          if (topup['amount'] is String) {
            topup['amount'] = double.parse(topup['amount']);
          } else if (topup['amount'] is int) {
            topup['amount'] = topup['amount'].toDouble();
          }
        }

        return topups;
      } else {
        throw Exception('Failed to load top-up requests');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

/*---------------------------------
Phương thức xác nhận yêu cầu nạp\
 tiền (cho admin)
-----------------------------------*/

  static Future<Map<String, dynamic>> approveWalletTopUp(
      String requestId) async {
    try {
      final url = '$baseUrl/admin/wallet/topups/$requestId/approve';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to approve top-up request');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

/*---------------------------------
Từ chối yêu cầu nạp tiền (cho admin)
-----------------------------------*/
  static Future<Map<String, dynamic>> rejectWalletTopUp(
      String requestId) async {
    try {
      final url = '$baseUrl/admin/wallet/topups/$requestId/reject';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to reject top-up request');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
