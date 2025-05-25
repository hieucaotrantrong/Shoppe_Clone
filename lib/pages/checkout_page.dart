import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:food_app/pages/bottomnav.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = false;
  double _walletBalance = 0;
  String? _userId;
  String _paymentMethod = 'wallet'; // Mặc định là thanh toán bằng ví

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy ID người dùng từ SharedPreferences
      _userId = await SharedPreferenceHelper().getUserId();
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng đăng nhập để thanh toán')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Lấy số dư ví
      final walletData = await ApiService.getWalletBalance(_userId!);
      setState(() {
        _walletBalance = walletData['balance'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading wallet balance: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải thông tin ví: $e')),
      );
    }
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
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Kiểm tra phương thức thanh toán
      if (_paymentMethod == 'wallet') {
        // Kiểm tra số dư ví
        if (_walletBalance < widget.totalAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Số dư ví không đủ để thanh toán')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // In ra thông tin chi tiết giỏ hàng để debug
      print('Cart items for order:');
      for (var item in widget.cartItems) {
        print(
            '- ID: ${item['id']}, Name: ${item['name']}, Price: ${item['price']}, Quantity: ${item['quantity']}');
      }

      // Gọi API tạo đơn hàng với phương thức thanh toán
      final result = await ApiService.createOrder(
        int.parse(_userId!),
        widget.totalAmount,
        widget.cartItems,
        paymentMethod: _paymentMethod,
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
          SnackBar(
              content: Text('Đặt hàng thất bại: ${result?['message'] ?? ''}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thanh toán'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin đơn hàng
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin đơn hàng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: widget.cartItems.length,
                              itemBuilder: (context, index) {
                                final item = widget.cartItems[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      // Thêm ảnh sản phẩm
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: item['image'] != null &&
                                                item['image']
                                                    .toString()
                                                    .isNotEmpty
                                            ? Image.network(
                                                item['image'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color:
                                                            Colors.grey[600]),
                                                  );
                                                },
                                              )
                                            : Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.grey[300],
                                                child: Icon(Icons.fastfood,
                                                    color: Colors.grey[600]),
                                              ),
                                      ),
                                      SizedBox(width: 12),
                                      // Thông tin sản phẩm
                                      Expanded(
                                        child: Text(
                                          '${item['name']} x ${item['quantity']}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      Text(
                                        '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(item['price'] * item['quantity'])}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng tiền:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(widget.totalAmount)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Phương thức thanh toán
                    Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Thanh toán bằng ví
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: Colors.green),
                          SizedBox(width: 8),
                          Text('Thanh toán bằng ví'),
                        ],
                      ),
                      subtitle: Text(
                          'Số dư: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(_walletBalance)}'),
                      value: 'wallet',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),

                    // Thanh toán khi nhận hàng
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.money, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Thanh toán khi nhận hàng'),
                        ],
                      ),
                      value: 'cod',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),

                    SizedBox(height: 24),

                    // Nút đặt hàng
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Xác nhận đặt hàng',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
