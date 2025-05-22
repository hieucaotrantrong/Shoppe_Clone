import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({Key? key}) : super(key: key);

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? userId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  Map<String, List<Map<String, dynamic>>> _orderItems = {};
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Thêm hàm kiểm tra API
  Future<void> _checkApiEndpoints() async {
    try {
      // Kiểm tra các endpoint khác nhau
      final endpoints = [
        '/orders/${_orders.first['id']}/items',
        '/api/orders/${_orders.first['id']}/items',
      ];

      for (var endpoint in endpoints) {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}$endpoint'),
          headers: {'Content-Type': 'application/json'},
        );

        print('Endpoint $endpoint status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking endpoints: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _getUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getUserInfo() async {
    try {
      userId = await SharedPreferenceHelper().getUserId();
      await _fetchOrders();
    } catch (e) {
      print("Error loading user info: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchOrders() async {
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('Fetching orders for user $userId');
      final orders = await ApiService.getUserOrders(userId!);

      if (!mounted) return;

      print('Received ${orders.length} orders');

      setState(() {
        _orders = orders;
      });

      // Lấy chi tiết cho mỗi đơn hàng ngay lập tức
      if (orders.isNotEmpty) {
        await _fetchOrderItems();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchOrderItems() async {
    Map<String, List<Map<String, dynamic>>> newOrderItems = {};

    for (var order in _orders) {
      try {
        final orderId = order['id'].toString();
        print("Fetching items for order #$orderId");

        // Lấy thông tin sản phẩm từ API
        final orderItemsResponse = await ApiService.getOrderItems(orderId);

        if (!mounted) return;

        if (orderItemsResponse.isNotEmpty) {
          print(
              "Received ${orderItemsResponse.length} items for order #$orderId");

          // Lưu thông tin sản phẩm
          newOrderItems[orderId] = orderItemsResponse;

          // Debug thông tin sản phẩm đầu tiên
          if (orderItemsResponse.isNotEmpty) {
            print("First item details: ${orderItemsResponse[0]}");
          }
        } else {
          print("No items received for order #$orderId");
        }
      } catch (e) {
        print("Error fetching order items for order ${order['id']}: $e");
      }
    }

    if (mounted) {
      setState(() {
        _orderItems = newOrderItems;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders(String status) {
    return _orders.where((order) => order['status'] == status).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Bạn chưa có đơn hàng nào',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // Hàm mới để lấy tên sản phẩm từ đơn hàng
  String _getOrderTitle(String orderId) {
    if (_orderItems.containsKey(orderId) && _orderItems[orderId]!.isNotEmpty) {
      final items = _orderItems[orderId]!;
      final firstItem = items[0];
      final itemName = firstItem['product_name'] ??
          firstItem['name'] ??
          'Sản phẩm không tên';

      if (items.length > 1) {
        return '$itemName và ${items.length - 1} sản phẩm khác';
      } else {
        return itemName;
      }
    }
    return 'Đơn hàng #$orderId';
  }

  Widget _buildOrderList(String status) {
    final filteredOrders = _getFilteredOrders(status);

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final orderId = order['id'].toString();
        final orderDate =
            DateTime.parse(order['created_at'] ?? DateTime.now().toString());

        // Lấy tên sản phẩm từ đơn hàng
        String orderTitle = '';
        if (_orderItems.containsKey(orderId) &&
            _orderItems[orderId]!.isNotEmpty) {
          final items = _orderItems[orderId]!;
          final firstItem = items[0];
          final itemName = firstItem['product_name'] ??
              firstItem['name'] ??
              'Sản phẩm không tên';

          if (items.length > 1) {
            orderTitle = '$itemName và ${items.length - 1} sản phẩm khác';
          } else {
            orderTitle = itemName;
          }
        } else {
          // Nếu chưa có dữ liệu sản phẩm, hiển thị tên tạm thời
          orderTitle = 'Đơn hàng #$orderId';
        }

        // Đảm bảo total_amount là một số hợp lệ
        double totalAmount = 0;
        try {
          if (order['total_amount'] != null) {
            totalAmount = double.parse(order['total_amount'].toString());
          }
        } catch (e) {
          print("Error parsing total_amount: $e");
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        // Thay đổi ở đây - Sử dụng tên sản phẩm thay vì ID đơn hàng
                        _orderItems.containsKey(orderId) &&
                                _orderItems[orderId]!.isNotEmpty
                            ? _getOrderTitle(orderId)
                            : 'Đơn hàng đang tải...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['status'] ?? 'pending'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(order['status'] ?? 'pending'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Ngày đặt: ${dateFormat.format(orderDate)}'),
                const SizedBox(height: 8),
                Text(
                    'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalAmount)}'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _showOrderDetails(order);
                      },
                      child: const Text('Xem chi tiết'),
                    ),
                    if ((order['status'] ?? '') == 'pending')
                      ElevatedButton(
                        onPressed: () {
                          _cancelOrder(order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Hủy đơn'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Thêm hàm để hiển thị chi tiết đơn hàng
  void _showOrderDetails(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final items = _orderItems[orderId] ?? [];

    print("Showing details for order #$orderId with ${items.length} items");
    if (items.isNotEmpty) {
      print("First item in order: ${items[0]}");
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiết đơn hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('Mã đơn: #$orderId',
                  style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('Không có thông tin sản phẩm'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final productName = item['product_name'] ??
                              item['name'] ??
                              'Sản phẩm không tên';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[300],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildProductImage(item),
                              ),
                            ),
                            title: Text(
                              productName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text('Số lượng: ${item['quantity'] ?? 1}'),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(double.tryParse(item['price'].toString()) ?? 0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng tiền:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(double.tryParse(order['total_amount'].toString()) ?? 0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if ((order['status'] ?? '') == 'pending')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cancelOrder(order);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Hủy đơn hàng'),
                ),
            ],
          ),
        );
      },
    );
  }

  // Cập nhật hàm để hủy đơn hàng
  void _cancelOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận hủy đơn'),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _isLoading = true;
              });

              final result = await ApiService.updateOrderStatus(
                  order['id'].toString(), 'cancelled');

              if (result != null && result['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã hủy đơn hàng thành công')),
                );
                _fetchOrders();
              } else {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(result != null && result['message'] != null
                          ? result['message']
                          : 'Không thể hủy đơn hàng')),
                );
              }
            },
            child: Text('Có', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Cập nhật hàm để đồng bộ với trạng thái từ admin
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      case 'returning':
        return 'Đang yêu cầu trả';
      case 'returned':
        return 'Đã trả hàng';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'returning':
        return Colors.amber;
      case 'returned':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Kiểm tra xem đơn hàng có thể trả hay không (đã giao và trong vòng 7 ngày)
  bool _isOrderReturnable(Map<String, dynamic> order) {
    // Kiểm tra trạng thái đơn hàng
    if (order['status'] != 'delivered') {
      return false;
    }

    // Kiểm tra thời gian
    try {
      final deliveredDate = DateTime.parse(
          order['delivered_at'] ?? order['updated_at'] ?? order['created_at']);
      final now = DateTime.now();
      final difference = now.difference(deliveredDate).inDays;

      // Chỉ cho phép trả hàng trong vòng 7 ngày
      return difference <= 7;
    } catch (e) {
      print("Error checking returnable status: $e");
      return false;
    }
  }

  // Xây dựng danh sách đơn hàng có thể trả
  Widget _buildReturnableOrderList() {
    final returnableOrders =
        _orders.where((order) => _isOrderReturnable(order)).toList();

    if (returnableOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_return, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có đơn hàng nào có thể trả',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Chỉ đơn hàng đã giao trong vòng 7 ngày mới có thể trả',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: returnableOrders.length,
      itemBuilder: (context, index) {
        final order = returnableOrders[index];
        final orderId = order['id'].toString();
        final orderDate =
            DateTime.parse(order['created_at'] ?? DateTime.now().toString());
        final deliveredDate = DateTime.parse(order['delivered_at'] ??
            order['updated_at'] ??
            order['created_at']);

        // Tính số ngày còn lại để trả hàng
        final now = DateTime.now();
        final daysLeft = 7 - now.difference(deliveredDate).inDays;

        // Đảm bảo total_amount là một số hợp lệ
        double totalAmount = 0;
        try {
          if (order['total_amount'] != null) {
            totalAmount = double.parse(order['total_amount'].toString());
          }
        } catch (e) {
          print("Error parsing total_amount: $e");
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getOrderTitle(orderId),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Còn $daysLeft ngày để trả',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Ngày đặt: ${DateFormat('dd/MM/yyyy').format(orderDate)}'),
                Text(
                    'Ngày giao: ${DateFormat('dd/MM/yyyy').format(deliveredDate)}'),
                const SizedBox(height: 8),
                Text(
                    'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalAmount)}'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _requestReturn(order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Yêu cầu trả hàng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Xử lý yêu cầu trả hàng
  void _requestReturn(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final items = _orderItems[orderId] ?? [];
    String? selectedReason;

    // Danh sách lý do trả hàng
    final List<String> returnReasons = [
      'Hàng lỗi, không hoạt động',
      'Hàng hết hạn sử dụng',
      'Khác với mô tả',
      'Hàng đã qua sử dụng',
      'Hàng giả, nhái',
      'Hàng nguyên vẹn nhưng không còn như cầu (sẽ trả nguyên seal, tem, hộp sản phẩm)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yêu cầu trả hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('Chọn lý do trả hàng:'),
                  SizedBox(height: 8),
                  // Danh sách lý do
                  ...returnReasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                    );
                  }).toList(),
                  SizedBox(height: 16),
                  // Nút xác nhận
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: selectedReason == null
                          ? null
                          : () async {
                              Navigator.pop(context);
                              try {
                                setState(() {
                                  _isLoading = true;
                                });

                                // Gọi API để cập nhật trạng thái đơn hàng thành "returning"
                                final result =
                                    await ApiService.updateOrderStatus(
                                        order['id'].toString(), 'returning',
                                        reason: selectedReason);

                                if (result != null &&
                                    result['status'] == 'success') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Đã gửi yêu cầu trả hàng thành công')),
                                  );
                                  _fetchOrders();
                                } else {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result != null &&
                                                result['message'] != null
                                            ? result['message']
                                            : 'Không thể gửi yêu cầu trả hàng')),
                                  );
                                }
                              } catch (e) {
                                print("Error requesting return: $e");
                                setState(() {
                                  _isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text('Xác nhận'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Thêm hàm mới để xây dựng widget hiển thị ảnh sản phẩm
  Widget _buildProductImage(Map<String, dynamic> item) {
    // In toàn bộ dữ liệu item để debug
    print("Full item data: $item");

    // Kiểm tra và xây dựng URL ảnh
    String? imageUrl;

    // Kiểm tra các trường có thể chứa đường dẫn ảnh
    if (item['image_path'] != null &&
        item['image_path'].toString().isNotEmpty) {
      imageUrl = item['image_path'];
    } else if (item['ImagePath'] != null &&
        item['ImagePath'].toString().isNotEmpty) {
      imageUrl = item['ImagePath'];
    } else if (item['image'] != null && item['image'].toString().isNotEmpty) {
      imageUrl = item['image'];
    }

    print("Image URL extracted: $imageUrl");

    // Nếu có URL ảnh, hiển thị ảnh
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Kiểm tra xem URL đã đầy đủ chưa
      if (!imageUrl.startsWith('http')) {
        // Nếu là đường dẫn tương đối, thêm baseUrl
        imageUrl = '${ApiService.baseUrl}/$imageUrl';
      }

      print("Final image URL: $imageUrl");

      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          print("Error loading image: $error for URL: $imageUrl");
          return _buildFallbackImage(item);
        },
      );
    } else {
      print("No image URL found, using fallback");
      return _buildFallbackImage(item);
    }
  }

  // Hàm tạo widget fallback khi không có ảnh
  Widget _buildFallbackImage(Map<String, dynamic> item) {
    final productName = item['product_name'] ?? item['name'] ?? 'SP';
    return Center(
      child: Text(
        productName.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn đã mua'),
        backgroundColor: const Color(0xFFff5722),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true, // Cho phép cuộn nếu có nhiều tab
          tabs: const [
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Đã giao'),
            Tab(text: 'Trả hàng'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Bạn chưa có đơn hàng nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Làm mới'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList('pending'),
                    _buildOrderList('processing'),
                    _buildOrderList('shipped'),
                    _buildOrderList('delivered'),
                    _buildReturnableOrderList(),
                  ],
                ),
    );
  }
}
