import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:intl/intl.dart';

class ManageOrders extends StatefulWidget {
  const ManageOrders({Key? key}) : super(key: key);

  @override
  State<ManageOrders> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends State<ManageOrders> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = ApiService.getAllOrders();
    });
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

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                    final orderDate = DateTime.parse(order['created_at']);

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
                            Text('Khách hàng: ${order['user_name']}'),
                            Row(
                              children: [
                                Text('Trạng thái: '),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order['status']),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _getStatusText(order['status']),
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
                                ...List.generate(
                                  (order['items'] as List).length,
                                  (i) {
                                    final item = (order['items'] as List)[i];
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 5),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              '${item['quantity']}x ${item['name']}'),
                                          Text(
                                              '₫${item['price'] * item['quantity']}'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tổng cộng:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '₫${order['total_amount']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFff5722),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'Cập nhật trạng thái:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
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

  Widget _buildStatusButton(
      String orderId, String status, String label, Color color) {
    return ElevatedButton(
      onPressed: () => _updateOrderStatus(orderId, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size(0, 30),
      ),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }
}
