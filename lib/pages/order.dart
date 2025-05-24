import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:food_app/pages/bottomnav.dart';
import 'package:food_app/pages/checkout_page.dart';
import 'package:intl/intl.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;

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
                    final item = widget.cartItems[index];
                    
                    // Chuyển đổi giá từ String sang double nếu cần
                    double price = 0;
                    if (item['price'] is String) {
                      price = double.tryParse(item['price']) ?? 0;
                    } else {
                      price = (item['price'] ?? 0).toDouble();
                    }
                    
                    // Định dạng giá tiền
                    String formattedPrice = NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '₫',
                      decimalDigits: 0,
                    ).format(price);
                    
                    return ListTile(
                      leading: Image.network(
                        item['image'] ??
                            'https://via.placeholder.com/100',
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
                      title: Text(item['name'] ?? 'Unknown Product'),
                      subtitle: Text('Số lượng: ${item['quantity']}'),
                      trailing: Text(
                        formattedPrice,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
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
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tổng tiền:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tổng tiền: ${NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: '₫',
                            decimalDigits: 0,
                          ).format(_calculateTotal(widget.cartItems))}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Đặt hàng",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
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

    // Tính tổng tiền
    double totalAmount = _calculateTotal(widget.cartItems);

    // Chuyển đến trang thanh toán
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          cartItems: widget.cartItems,
          totalAmount: totalAmount,
        ),
      ),
    );
  }
}







