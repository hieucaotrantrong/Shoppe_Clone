import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ManageOrders extends StatefulWidget {
  const ManageOrders({Key? key}) : super(key: key);

  @override
  State<ManageOrders> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends State<ManageOrders> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
    
    // Tự động làm mới danh sách đơn hàng mỗi 30 giây
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _refreshOrders();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
      _ordersFuture = ApiService.getAllOrders();
    });
    
    try {
      final orders = await _ordersFuture;
      print('Fetched ${orders.length} orders');
      for (var order in orders) {
        print('Order #${order['id']}: ${order['total_amount']} - ${order['status']}');
        if (order['items'] != null) {
          print('  Items: ${order['items'].length}');
        } else {
          print('  No items found');
        }
      }
    } catch (e) {
      print('Error refreshing orders: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Updating order $orderId to status: $newStatus');

      // Kiểm tra orderId
      if (orderId.isEmpty || orderId == 'null') {
        throw Exception('Invalid order ID: $orderId');
      }

      // Đảm bảo status là một trong các giá trị hợp lệ
      final validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
      if (!validStatuses.contains(newStatus)) {
        throw Exception('Invalid status: $newStatus');
      }

      final result = await ApiService.updateOrderStatus(orderId, newStatus);
      
      print('Update result: $result');

      if (result != null && result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trạng thái đơn hàng đã được cập nhật thành $newStatus')),
        );
        _refreshOrders();
      } else {
        String errorMessage = 'Không thể cập nhật trạng thái đơn hàng';
        if (result != null && result['message'] != null) {
          errorMessage += ': ${result['message']}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
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
        title: Text('Quản lý đơn hàng'),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Không có đơn hàng nào'));
                }

                final orders = snapshot.data!;
                print('Building UI for ${orders.length} orders');
                
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    print('Rendering order: $order');
                    
                    // Xử lý ngày đặt hàng an toàn
                    DateTime orderDate;
                    try {
                      final dateString = order['created_at'] ?? order['order_date'];
                      orderDate = dateString != null 
                          ? DateTime.parse(dateString.toString()) 
                          : DateTime.now();
                    } catch (e) {
                      print('Error parsing date: $e');
                      orderDate = DateTime.now();
                    }
                    
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                    
                    // Xử lý trạng thái đơn hàng an toàn
                    final status = order['status'] ?? 'pending';
                    
                    // Xử lý tên người dùng an toàn
                    final userName = order['user_name'] ?? 'Không xác định';
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      elevation: 2,
                      child: ExpansionTile(
                        title: Text(
                          'Đơn hàng #${order['id']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ngày đặt: ${dateFormat.format(orderDate)}'),
                            Text('Khách hàng: $userName'),
                            Row(
                              children: [
                                Text('Trạng thái: '),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          '₫${order['total_amount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFff5722),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chi tiết đơn hàng:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                if (order['items'] != null && order['items'] is List && (order['items'] as List).isNotEmpty)
                                  ...List.generate(
                                    (order['items'] as List).length,
                                    (i) {
                                      final item = (order['items'] as List)[i];
                                      // Ưu tiên sử dụng tên sản phẩm từ product_name nếu có
                                      final itemName = item['product_name'] ?? 
                                                       item['name'] ?? 
                                                       'Sản phẩm không xác định';
                                      final itemQuantity = item['quantity'] ?? 1;
                                      final itemPrice = item['price'] ?? 0;
                                      
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 5),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('$itemQuantity x $itemName'),
                                            Text('₫${itemPrice * itemQuantity}'),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Text('Không có thông tin chi tiết sản phẩm'),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _updateOrderStatus(order['id'].toString(), 'processing'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size(80, 30),
                                        textStyle: TextStyle(fontSize: 12),
                                      ),
                                      child: Text('Đang xử lý'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _updateOrderStatus(order['id'].toString(), 'shipped'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size(80, 30),
                                        textStyle: TextStyle(fontSize: 12),
                                      ),
                                      child: Text('Đang giao'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _updateOrderStatus(order['id'].toString(), 'delivered'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size(80, 30),
                                        textStyle: TextStyle(fontSize: 12),
                                      ),
                                      child: Text('Đã giao'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _updateOrderStatus(order['id'].toString(), 'cancelled'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size(80, 30),
                                        textStyle: TextStyle(fontSize: 12),
                                      ),
                                      child: Text('Hủy'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildStatusButton(String orderId, String status, String label, Color color) {
    // Lấy trạng thái hiện tại của đơn hàng
    final currentStatus = _getCurrentOrderStatus(orderId);
    
    // Kiểm tra xem nút có nên bị vô hiệu hóa không
    bool isDisabled = false;
    
    // Nếu đơn hàng đã bị hủy, vô hiệu hóa tất cả các nút khác
    if (currentStatus == 'cancelled' && status != 'cancelled') {
      isDisabled = true;
    }
    
    // Nếu đơn hàng đã giao, vô hiệu hóa tất cả các nút khác
    if (currentStatus == 'delivered' && status != 'delivered') {
      isDisabled = true;
    }
    
    // Nếu đơn hàng đang ở trạng thái hiện tại, vô hiệu hóa nút đó
    if (currentStatus == status) {
      isDisabled = true;
    }
    
    return ElevatedButton(
      onPressed: isDisabled ? null : () => _updateOrderStatus(orderId, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? Colors.grey : color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size(80, 30),
        textStyle: TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  // Phương thức mới để lấy trạng thái hiện tại của đơn hàng
  String _getCurrentOrderStatus(String orderId) {
    try {
      final orders = _ordersFuture as Future<List<Map<String, dynamic>>>;
      final ordersList = orders.then((list) {
        return list.firstWhere((order) => order['id'].toString() == orderId, 
                              orElse: () => {'status': 'pending'});
      });
      
      // Vì không thể đồng bộ truy cập Future, trả về giá trị mặc định
      return 'pending';
    } catch (e) {
      print('Error getting current order status: $e');
      return 'pending';
    }
  }
}












