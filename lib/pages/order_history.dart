import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getUserInfo();

    // Tự động làm mới danh sách đơn hàng mỗi 30 giây
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) _fetchOrders();
    });
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
      final orders = await ApiService.getUserOrders(userId!);

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      // Lấy chi tiết cho mỗi đơn hàng
      _fetchOrderItems();
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
    for (var order in _orders) {
      try {
        final orderId = order['id'].toString();
        final orderItemsResponse = await ApiService.getOrderItems(orderId);

        if (!mounted) return;

        if (orderItemsResponse.isNotEmpty) {
          setState(() {
            _orderItems[orderId] = orderItemsResponse;
          });
        }
      } catch (e) {
        print("Error fetching order items: $e");
      }
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
      final itemName = firstItem['name'] ?? 'Sản phẩm không tên';

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
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: item['image_path'] != null &&
                                          item['image_path']
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(
                                          '${ApiService.baseUrl}/${item['image_path']}')
                                      : AssetImage(
                                              'assets/images/placeholder.png')
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              item['name'] ?? 'Sản phẩm không tên',
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

              final result =
                  await ApiService.cancelOrder(order['id'].toString());

              if (result['status'] == 'success') {
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
                      content:
                          Text(result['message'] ?? 'Không thể hủy đơn hàng')),
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
      default:
        return Colors.grey;
    }
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
          tabs: const [
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Đã giao'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('pending'),
                _buildOrderList('processing'),
                _buildOrderList('shipped'),
                _buildOrderList('delivered'),
              ],
            ),
    );
  }
}
