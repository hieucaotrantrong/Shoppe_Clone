class MySQLConfig {
  static const String host = 'localhost'; // Hoặc IP của MySQL server
  static const int port = 3306;
  static const String user = 'root';
  static const String password = 'hieu@1010'; // Thay bằng mật khẩu của bạn
  static const String db = 'food_app';

  // Tên các bảng
  static const String usersTable = 'users';
  static const String foodItemsTable = 'food_items';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
}

