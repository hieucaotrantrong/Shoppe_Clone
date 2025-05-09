import 'package:flutter/material.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:food_app/widgets/home/header_section.dart';
import 'package:food_app/widgets/home/categories_section.dart';
import 'package:food_app/widgets/home/products_grid.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? userName = "";
  String searchQuery = "";
  String selectedCategory = "All";
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  _getUserName() async {
    userName = await SharedPreferenceHelper().getUserName();
    setState(() {
      _isLoading = false;
    });
  }

  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
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
                    selectedCategory: selectedCategory,
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
                        selectedCategory == "All" ? null : selectedCategory,
                    searchQuery: searchQuery.isEmpty ? null : searchQuery,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}


