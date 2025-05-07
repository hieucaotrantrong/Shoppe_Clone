import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  final String selectedCategory;
  final Function() onAllTap;
  final Function() onBurgerTap;
  final Function() onPizzaTap;
  final Function() onSaladTap;
  final Function() onIceCreamTap;
  final Function() onDrinksTap;
  final Function() onPastaTap;

  const CategoriesSection({
    Key? key,
    required this.selectedCategory,
    required this.onAllTap,
    required this.onBurgerTap,
    required this.onPizzaTap,
    required this.onSaladTap,
    required this.onIceCreamTap,
    required this.onDrinksTap,
    required this.onPastaTap,
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
                  'images/all.png',
                  selectedCategory == "All",
                  'All',
                  onAllTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/burger.png',
                  selectedCategory == "Burger",
                  'Burger',
                  onBurgerTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/pizza.png',
                  selectedCategory == "Pizza",
                  'Pizza',
                  onPizzaTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/salad.png',
                  selectedCategory == "Salad",
                  'Salad',
                  onSaladTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/ice-cream.png',
                  selectedCategory == "Dessert",
                  'Dessert',
                  onIceCreamTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/drinks.png',
                  selectedCategory == "Drinks",
                  'Drinks',
                  onDrinksTap,
                ),
                const SizedBox(width: 15),
                _buildCategoryButton(
                  'images/pasta.png',
                  selectedCategory == "Pasta",
                  'Pasta',
                  onPastaTap,
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
              color: isSelected ? Colors.black87 : Colors.white,
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
              color: isSelected ? Colors.white : Colors.black87,
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

