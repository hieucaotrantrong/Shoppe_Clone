import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/widgets/home/product_card.dart';

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
  late Future<List<Map<String, dynamic>>> _foodItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  @override
  void didUpdateWidget(ProductsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.searchQuery != widget.searchQuery) {
      _loadFoodItems();
    }
  }

  void _loadFoodItems() {
    _foodItemsFuture = _getFoodItems();
  }

  // Phương thức mới để lấy dữ liệu từ ApiService
  Future<List<Map<String, dynamic>>> _getFoodItems() async {
    try {
      List<Map<String, dynamic>> items = await ApiService.getFoodItems();

      // Lọc theo danh mục nếu có
      if (widget.category != null && widget.category!.isNotEmpty) {
        items = items
            .where((item) =>
                item['category'].toString().toLowerCase() ==
                widget.category!.toLowerCase())
            .toList();
      }

      // Lọc theo từ khóa tìm kiếm nếu có
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        items = items
            .where((item) => item['name']
                .toString()
                .toLowerCase()
                .contains(widget.searchQuery!.toLowerCase()))
            .toList();
      }

      return items;
    } catch (e) {
      print('Error loading food items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Popular Items",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _foodItemsFuture,
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
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount =
                  screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);

              return Container(
                constraints: BoxConstraints(
                  maxWidth: 1200,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
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
                    return ProductCard(
                      product: product,
                      docId: item['id'].toString(),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
