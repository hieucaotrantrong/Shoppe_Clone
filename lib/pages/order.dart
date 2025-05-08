import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/services/api_service.dart'; // Thay thế mysql_service
import 'package:food_app/services/shared_pref.dart';

class Order extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  const Order({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Giỏ hàng (${cartItems.length})"),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => cartProvider.clearCart(),
            )
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Giỏ hàng trống"))
          : Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 800,
                ),
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Dismissible(
                        key: Key(item['name']),
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
                                Image.network(
                                  item['image'] ?? 'https://via.placeholder.com/100',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'images/placeholder.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                                SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontSize: 18.0,
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
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10.0,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tổng tiền:",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${calculateTotal(cartItems).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => placeOrder(context, cartProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFff5722),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      "Đặt hàng",
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      total += (item['price'] * item['quantity']);
    }
    return total;
  }

  Future<void> placeOrder(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    try {
      // Hiển thị dialog xác nhận
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Xác nhận đặt hàng"),
          content: Text("Bạn có chắc chắn muốn đặt hàng không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Đặt hàng"),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Lấy userId từ SharedPreferences
      final userId = await SharedPreferenceHelper().getUserId();
      if (userId == null || userId.isEmpty) {
        Navigator.of(context).pop(); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vui lòng đăng nhập để đặt hàng")),
        );
        return;
      }

      // Tính tổng tiền
      final totalAmount = calculateTotal(cartProvider.cartItems);

      // In thông tin để debug
      print('Sending order: userId=$userId, totalAmount=$totalAmount');
      print('Items: ${cartProvider.cartItems}');
      
      // Kiểm tra id của sản phẩm
      for (var item in cartProvider.cartItems) {
        print('Product ID: ${item['id']}, Type: ${item['id'].runtimeType}');
      }

      // Tạo đơn hàng trong cơ sở dữ liệu
      final result = await ApiService.createOrder(
        int.parse(userId),
        totalAmount,
        cartProvider.cartItems,
      );

      // Đóng loading dialog
      Navigator.of(context).pop();

      if (result != null && result['status'] == 'success') {
        // Xóa giỏ hàng
        cartProvider.clearCart();

        // Hiển thị thông báo thành công
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Đặt hàng thành công"),
            content: Text("Mã đơn hàng của bạn là: #${result['data']['order_id']}"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Quay lại trang trước
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đặt hàng thất bại. Vui lòng thử lại sau.")),
        );
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }
}







