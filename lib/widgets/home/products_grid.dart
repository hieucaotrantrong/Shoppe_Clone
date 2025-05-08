import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/widgets/home/product_card.dart';
import 'package:food_app/pages/details.dart';

class ProductsGrid extends StatefulWidget {
  final String? category;
  final String? searchQuery;

  const ProductsGrid({
    Key? key,
    this.category,
    this.searchQuery,
  }) : super(key: key);

  @override
  State<ProductsGrid> createState() => _ProductsGridState();
}

class _ProductsGridState extends State<ProductsGrid> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _getProducts();
  }

  @override
  void didUpdateWidget(ProductsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.searchQuery != widget.searchQuery) {
      setState(() {
        _productsFuture = _getProducts();
      });
    }
  }

  // Phương thức để lấy dữ liệu từ ApiService
  Future<List<Map<String, dynamic>>> _getProducts() async {
    try {
      final products = await ApiService.getProducts();
      return products;
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Sản phẩm phổ biến",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Xử lý khi nhấn "Xem tất cả"
                  },
                  child: Text(
                    "Xem tất cả",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No items available'));
              }

              final items = snapshot.data!;

              // Luôn hiển thị 2 sản phẩm trên một hàng
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Luôn 2 sản phẩm trên một hàng
                  childAspectRatio: 0.7, // Tỷ lệ khung hình sản phẩm
                  crossAxisSpacing: 10, // Khoảng cách ngang giữa các sản phẩm
                  mainAxisSpacing: 10, // Khoảng cách dọc giữa các hàng
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  // Chuyển đổi từ định dạng API sang định dạng cũ
                  Map<String, dynamic> product = {
                    'Name': item['name'],
                    'Price': item['price'],
                    'Category': item['category'],
                    'ImagePath': item['image_path'],
                    'Description': item['description'],
                  };
                  return ShopeeStyleProductCard(
                    product: product,
                    docId: item['id'].toString(),
                    discount: index % 3 == 0
                        ? 15
                        : (index % 2 == 0 ? 20 : 10), // Giảm giá ngẫu nhiên
                    soldCount: (100 + index * 7)
                        .toString(), // Số lượng đã bán ngẫu nhiên
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// Tạo một widget ProductCard mới theo phong cách Shopee
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
        // Sửa lại phần này để chuyển đến trang chi tiết sản phẩm
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm với badge giảm giá
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      product['ImagePath'] ?? 'images/default_food.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Thông tin sản phẩm
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    product["Name"] ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Giá sản phẩm
                  Row(
                    children: [
                      Text(
                        '₫${discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (discount > 0)
                        Text(
                          '₫${originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),

                  // Số lượng đã bán
                  const SizedBox(height: 4),
                  Text(
                    'Đã bán $soldCount',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
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









