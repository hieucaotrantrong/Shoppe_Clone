import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:food_app/pages/bottomnav.dart';

class Order extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const Order({super.key, required this.cartItems});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final totalAmount = _calculateTotal(widget.cartItems);

    return Scaffold(
      appBar: AppBar(
        title: Text("Giỏ hàng (${widget.cartItems.length})"),
        actions: [
          if (widget.cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => cartProvider.clearCart(),
            )
        ],
      ),
      body: widget.cartItems.isEmpty
          ? const Center(child: Text("Giỏ hàng trống"))
          : Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 800,
                ),
                child: ListView.builder(
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    // Kiểm tra index có hợp lệ không
                    if (index < 0 || index >= widget.cartItems.length) {
                      return SizedBox(); // Trả về widget trống nếu index không hợp lệ
                    }
                    
                    final item = widget.cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Dismissible(
                        key: Key(item['cart_item_id']?.toString() ?? item['name']),
                        onDismissed: (direction) {
                          cartProvider.removeItem(index);
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: Card(
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[300],
                                  ),
                                  child: item['image'] != null && item['image'].toString().isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item['image'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print("Error loading image: $error");
                                            // Hiển thị chữ cái đầu tiên của tên sản phẩm
                                            final productName = item['name'] ?? 'Sản phẩm';
                                            return Center(
                                              child: Text(
                                                productName.substring(0, 1).toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (item['name'] ?? 'SP').substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                ),
                                SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Sản phẩm không xác định',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        "\$${item['price']}",
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {
                                        if (item['quantity'] > 1) {
                                          cartProvider.updateQuantity(
                                            index,
                                            item['quantity'] - 1,
                                          );
                                        }
                                      },
                                    ),
                                    Text(
                                      "${item['quantity']}",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {
                                        cartProvider.updateQuantity(
                                          index,
                                          item['quantity'] + 1,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      bottomNavigationBar: widget.cartItems.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tổng cộng:",
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        "\$${totalAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFff5722),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : _placeOrder,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Đặt hàng",
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      total += (item['price'] * item['quantity']);
    }
    return total;
  }

  void _placeOrder() async {
    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giỏ hàng trống')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông tin người dùng từ SharedPreferences
      final userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Tính tổng tiền
      double totalAmount = 0;
      for (var item in widget.cartItems) {
        totalAmount += (item['price'] * item['quantity']);
      }

      // In ra thông tin chi tiết giỏ hàng để debug
      print('Cart items for order:');
      for (var item in widget.cartItems) {
        print('- ID: ${item['id']}, Name: ${item['name']}, Price: ${item['price']}, Quantity: ${item['quantity']}');
      }

      // Gọi API tạo đơn hàng
      final result = await ApiService.createOrder(
        int.parse(userId!),
        totalAmount,
        widget.cartItems,
      );

      if (result != null && result['status'] == 'success') {
        // Xóa giỏ hàng sau khi đặt hàng thành công
        Provider.of<CartProvider>(context, listen: false).clearCart();
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thành công')),
        );
        
        // Chuyển đến trang chủ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNav()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thất bại')),
        );
      }
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}










