import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  final String selectedCategory;
  final Function() onAllTap;
  final Function() onClothingTap;
  final Function() onShoesTap;
  final Function() onAccessoriesTap;
  final Function() onElectronicsTap;
  final Function() onSportsTap;
  final Function() onBeautyTap;

  const CategoriesSection({
    Key? key,
    required this.selectedCategory,
    required this.onAllTap,
    required this.onClothingTap,
    required this.onShoesTap,
    required this.onAccessoriesTap,
    required this.onElectronicsTap,
    required this.onSportsTap,
    required this.onBeautyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Danh mục",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryButton(
                  'images/all.jpg',
                  selectedCategory == "All",
                  'Tất cả',
                  onAllTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/icon1.png',
                  selectedCategory == "Clothing",
                  'Quần áo',
                  onClothingTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/short.jpg',
                  selectedCategory == "Shoes",
                  'Giày dép',
                  onShoesTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/nhan.jpg',
                  selectedCategory == "Accessories",
                  'Phụ kiện',
                  onAccessoriesTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/version.jpg',
                  selectedCategory == "Electronics",
                  'Điện tử',
                  onElectronicsTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/version2.jpg',
                  selectedCategory == "Sports",
                  'Thể thao',
                  onSportsTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/icon2.png',
                  selectedCategory == "Beauty",
                  'Làm đẹp',
                  onBeautyTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
      String icon, bool isSelected, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromARGB(221, 236, 82, 82)
                  : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              icon,
              height: 30,
              width: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black87 : Colors.grey[600],
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
