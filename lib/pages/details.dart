import 'package:flutter/material.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class Details extends StatefulWidget {
  final Map<String, dynamic> product;

  const Details({Key? key, required this.product}) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int quantity = 1;
  final int discount = 15; // Giả lập giảm giá 15%

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Kiểm tra và chuyển đổi giá từ String sang double nếu cần
    double originalPrice;
    if (widget.product["Price"] is String) {
      originalPrice = double.parse(widget.product["Price"]);
    } else {
      originalPrice = widget.product["Price"].toDouble();
    }
    
    final discountedPrice = originalPrice * (1 - discount / 100);

    
    print("Product details: ${widget.product}");
    print("Original price: $originalPrice");
    print("Discounted price: $discountedPrice");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Chi tiết sản phẩm"),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh sản phẩm
                  AspectRatio(
                    aspectRatio: 1,
                    child: widget.product['ImagePath'] != null && widget.product['ImagePath'].toString().isNotEmpty
                        ? Image.network(
                            widget.product['ImagePath'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print("Error loading image: $error");
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                          ),
                  ),
                  
                  // Thông tin giá và tên sản phẩm
                  Container(
                    padding: EdgeInsets.all(15),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '$discount% GIẢM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₫${discountedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (discount > 0)
                          Row(
                            children: [
                              Text(
                                '₫${originalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tiết kiệm ₫${(originalPrice - discountedPrice).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 12),
                        Text(
                          widget.product["Name"] ?? "Unknown",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star_half, color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 15),
                            Text(
                              'Đã bán 157',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Vận chuyển
                  Container(
                    padding: EdgeInsets.all(15),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 20, color: Colors.grey[700]),
                            SizedBox(width: 10),
                            Text(
                              'Vận chuyển',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Miễn phí vận chuyển',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Giao hàng trong 24h',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Số lượng
                  Container(
                    padding: EdgeInsets.all(15),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Text(
                          'Số lượng',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(width: 20),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: _decrementQuantity,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.remove, size: 16),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Colors.grey[300]!),
                                    right: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Text(
                                  quantity.toString(),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              InkWell(
                                onTap: _incrementQuantity,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.add, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Mô tả sản phẩm
                  Container(
                    padding: EdgeInsets.all(15),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mô tả sản phẩm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          widget.product["Description"] ?? "Không có mô tả",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom bar với nút thêm vào giỏ hàng
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.chat_outlined),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.shopping_cart_outlined),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF6600),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // In ra id để debug
                      print('Adding product to cart with id: ${widget.product["id"]}');
                      print('Product id type: ${widget.product["id"].runtimeType}');
                      
                      cartProvider.addToCart({
                        "id": widget.product["id"] ?? "1",
                        "name": widget.product["Name"],
                        "price": discountedPrice,
                        "image": widget.product["ImagePath"],
                      }, quantity);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm vào giỏ hàng'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Thêm vào giỏ hàng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}









