import 'package:flutter/material.dart';
import 'package:food_app/pages/details.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String docId;

  const ProductCard({
    Key? key,
    required this.product,
    required this.docId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 1200 ? 300.0 : screenWidth * 0.4;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(product: product),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxWidth * 1.4,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              height: maxWidth * 0.8,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: product['ImagePath'] != null &&
                        product['ImagePath'].isNotEmpty
                    ? Image.network(
                        product['ImagePath'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey[600]),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported,
                            size: 40, color: Colors.grey[600]),
                      ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product["Name"] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${product["Price"] ?? 0}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: () {
                          // Thêm tham số forceAdd = true để luôn thêm mới sản phẩm
                          Provider.of<CartProvider>(context, listen: false)
                              .addToCart({
                            "id": docId,
                            "name": product["Name"],
                            "price": product["Price"],
                            "image": product["ImagePath"],
                          }, 1, forceAdd: true);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${product["Name"]} to cart'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopeeStyleProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String docId;
  final int discount;
  final String soldCount;

  const ShopeeStyleProductCard({
    Key? key,
    required this.product,
    required this.docId,
    required this.discount,
    required this.soldCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final originalPrice = double.parse(product["Price"].toString());
    final discountedPrice = originalPrice * (1 - discount / 100);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Đảm bảo column chỉ chiếm không gian cần thiết
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm với tỷ lệ cố định
            AspectRatio(
              aspectRatio: 1.0, // Tỷ lệ 1:1 (hình vuông)
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: product["ImagePath"] != null &&
                            product["ImagePath"].toString().isNotEmpty
                        ? Image.network(
                            product["ImagePath"],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child:
                                    Icon(Icons.image_not_supported, size: 40),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, size: 40),
                          ),
                  ),
                  // Nhãn giảm giá
                  if (discount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          "-${discount}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Thông tin sản phẩm - Sử dụng Container với chiều cao cố định
            Container(
              height: 80, // Chiều cao cố định cho phần thông tin
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tên sản phẩm
                  Text(
                    product["Name"] ?? "",
                    maxLines: 1, // Giảm xuống 1 dòng
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12, // Giảm kích thước font
                    ),
                  ),
                  SizedBox(height: 4),
                  // Giá
                  Row(
                    children: [
                      Text(
                        "${_formatPrice(discountedPrice)}đ",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Giảm kích thước font
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${_formatPrice(originalPrice)}đ",
                          style: TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 10, // Giảm kích thước font
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Spacer(), // Đẩy phần "Đã bán" xuống dưới cùng
                  // Đã bán
                  Text(
                    "Đã bán $soldCount",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10, // Giảm kích thước font
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
