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

      final result = await ApiService.updateOrderStatus(orderId, newStatus);

      if (result != null && result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trạng thái đơn hàng đã được cập nhật')),
        );
        _refreshOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật trạng thái đơn hàng')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
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
                                      final itemName = item['name'] ?? 'Sản phẩm không xác định';
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
                                    _buildStatusButton(
                                        order['id'].toString(),
                                        'processing',
                                        'Đang xử lý',
                                        Colors.blue),
                                    _buildStatusButton(order['id'].toString(),
                                        'shipped', 'Đang giao', Colors.purple),
                                    _buildStatusButton(order['id'].toString(),
                                        'delivered', 'Đã giao', Colors.green),
                                    _buildStatusButton(order['id'].toString(),
                                        'cancelled', 'Hủy', Colors.red),
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
    return ElevatedButton(
      onPressed: () => _updateOrderStatus(orderId, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size(80, 30),
        textStyle: TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
}







