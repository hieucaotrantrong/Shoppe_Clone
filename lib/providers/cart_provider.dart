import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> product, int quantity,
      {bool forceAdd = false}) {
    print('Adding to cart: $product');

    if (product['id'] == null) {
      print('Warning: Product has no ID');
      return;
    }

    if (forceAdd) {
      String productName = product['name'] ??
          product['Name'] ??
          product['product_name'] ??
          'Sản phẩm không xác định';

      print('Force adding product to cart: $productName');

      _cartItems.add({
        'id': product['id'],
        'name': productName,
        'price': product['price'] ?? product['Price'] ?? 0,
        'image': product['image'] ??
            product['image_path'] ??
            product['ImagePath'] ??
            '',
        'quantity': quantity,
        'cart_item_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      notifyListeners();
      return;
    }

    int existingIndex =
        _cartItems.indexWhere((item) => item['id'] == product['id']);

    if (existingIndex != -1) {
      //
      _cartItems[existingIndex]['quantity'] += quantity;
    } else {
      /*---------------------------------
       - Nếu chưa có, thêm mới với đầy đủ thông tin
       -----------------------------------*/

      String productName = product['name'] ??
          product['Name'] ??
          product['product_name'] ??
          'Sản phẩm không xác định';

      print('Product name for cart: $productName');

      _cartItems.add({
        'id': product['id'],
        'name': productName,
        'price': product['price'] ?? product['Price'] ?? 0,
        'image': product['image'] ??
            product['image_path'] ??
            product['ImagePath'] ??
            '',
        'quantity': quantity,
      });
    }
    notifyListeners();
  }

/*---------------------------------
 Cập nhật số lượng sản phẩm
-----------------------------------*/

  void updateQuantity(int index, int newQuantity) {
    if (index < 0 || index >= _cartItems.length) {
      print(
          'Error: Invalid index $index for cart items with length ${_cartItems.length}');
      return;
    }

    if (newQuantity > 0) {
      _cartItems[index]['quantity'] = newQuantity;
      notifyListeners();
    }
  }

/*---------------------------------
Xóa sản phẩm khỏi giỏ hàng
-----------------------------------*/

  void removeItem(int index) {
    if (index < 0 || index >= _cartItems.length) {
      print(
          'Error: Invalid index $index for cart items with length ${_cartItems.length}');
      return;
    }

    _cartItems.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  int get itemCount {
    return _cartItems.length;
  }

  int get totalItemCount {
    int count = 0;
    for (var item in _cartItems) {
      count += (item['quantity'] as int);
    }
    return count;
  }
}
