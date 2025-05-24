import 'package:flutter/material.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:food_app/widgets/home/header_section.dart';
import 'package:food_app/widgets/home/categories_section.dart';
import 'package:food_app/widgets/home/products_grid.dart';
import 'package:food_app/pages/details.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isLoading = true;
  String? userName;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategory = "All";
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _getProducts();
    _getCategories();

    // Thiết lập timer để tự động làm mới thông báo tin nhắn
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Kích hoạt rebuild để HeaderSection cập nhật số tin nhắn chưa đọc
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserData() async {
    userName = await SharedPreferenceHelper().getUserName();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getProducts() async {
    // Implement product loading logic
    setState(() {
      _products = [];
    });
  }

  Future<void> _getCategories() async {
    // Implement categories loading logic
    setState(() {
      _categories = [];
    });
  }

  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  // Thêm banner quảng cáo
  Widget _buildPromoBanner() {
    return Container(
      height: 150,
      color: Colors.blue,
      child: Center(
        child: Text(
          'Banner Quảng Cáo',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }

  // Trong phần hiển thị sản phẩm phổ biến
  Widget _buildPopularProductItem(Map<String, dynamic> product) {
    // Chuyển đổi giá từ String sang double nếu cần
    double price = 0;
    if (product['price'] is String) {
      price = double.tryParse(product['price']) ?? 0;
    } else {
      price = (product['price'] ?? 0).toDouble();
    }

    // Đảm bảo giá được hiển thị đúng định dạng với đơn vị tiền tệ Việt Nam
    String formattedPrice = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(price);

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                product['image_path'] ?? 'https://via.placeholder.com/150',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/placeholder.png',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown Product',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    formattedPrice,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section (Greeting, Search Bar, Cart Icon)
                  HeaderSection(
                    userName: userName,
                    searchController: searchController,
                    searchQuery: searchQuery,
                    handleSearch: _handleSearch,
                    cartProvider: cartProvider,
                  ),

                  // Categories Section
                  CategoriesSection(
                    selectedCategory: _selectedCategory,
                    onAllTap: () => _selectCategory("All"),
                    onClothingTap: () => _selectCategory("Clothing"),
                    onShoesTap: () => _selectCategory("Shoes"),
                    onAccessoriesTap: () => _selectCategory("Accessories"),
                    onElectronicsTap: () => _selectCategory("Electronics"),
                    onSportsTap: () => _selectCategory("Sports"),
                    onBeautyTap: () => _selectCategory("Beauty"),
                  ),

                  // Products Grid
                  ProductsGrid(
                    category:
                        _selectedCategory == "All" ? null : _selectedCategory,
                    searchQuery: searchQuery.isEmpty ? null : searchQuery,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
