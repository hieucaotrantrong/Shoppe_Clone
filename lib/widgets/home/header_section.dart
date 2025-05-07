import 'package:flutter/material.dart';
import 'package:food_app/pages/order.dart';
import 'package:food_app/providers/cart_provider.dart';

class HeaderSection extends StatelessWidget {
  final String? userName;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) handleSearch;
  final CartProvider cartProvider;

  const HeaderSection({
    Key? key,
    required this.userName,
    required this.searchController,
    required this.searchQuery,
    required this.handleSearch,
    required this.cartProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(context),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${userName ?? 'User'}",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(221, 236, 220, 182)),
            ),
            Text(
              "Chào mừng bạn đến với Shoppe",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        _buildCartButton(context),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: searchController,
        onChanged: handleSearch,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey[600]),
          hintText: "Tìm kiếm",
          hintStyle: TextStyle(color: Colors.grey[500]),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    searchController.clear();
                    handleSearch('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Order(cartItems: cartProvider.cartItems),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 28),
            if (cartProvider.cartItems.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    cartProvider.cartItems.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
