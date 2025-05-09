import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> product, int quantity) {
    // In ra thông tin sản phẩm để debug
    print('Adding to cart: $product');
    
    // Đảm bảo product có id
    if (product['id'] == null) {
      print('Warning: Product has no ID');
      return;
    }
    
    // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
    int existingIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);

    if (existingIndex != -1) {
      // Nếu đã có, tăng số lượng
      _cartItems[existingIndex]['quantity'] += quantity;
    } else {
      // Nếu chưa có, thêm mới với đầy đủ thông tin
      // Kiểm tra các trường hợp khác nhau của tên sản phẩm
      String productName = product['name'] ?? 
                           product['Name'] ?? 
                           product['product_name'] ?? 
                           'Sản phẩm không xác định';
      
      print('Product name for cart: $productName');
      
      _cartItems.add({
        'id': product['id'],
        'name': productName,
        'price': product['price'] ?? product['Price'] ?? 0,
        'image': product['image'] ?? product['image_path'] ?? product['ImagePath'] ?? '',
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
