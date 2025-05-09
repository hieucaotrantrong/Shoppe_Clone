import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> product, int quantity) {
    
    int existingIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);

    if (existingIndex != -1) {
    
      _cartItems[existingIndex]['quantity'] += quantity;
    } else {
      
      _cartItems.add({
        'id': product['id'],
        'name': product['name'],
        'price': product['price'],
        'image': product['image'],
        'quantity': quantity,
      });
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    _cartItems[index]['quantity'] = quantity;
    notifyListeners();
  }

  void clearCart() {
    _cartItems = [];
    notifyListeners();
  }

  double get totalAmount {
    double total = 0;
    for (var item in _cartItems) {
      total += (item['price'] * item['quantity']);
    }
    return total;
  }

  int get itemCount {
    return _cartItems.length;
  }
}
