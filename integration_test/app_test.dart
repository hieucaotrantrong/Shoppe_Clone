import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:food_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login and Register Test', (tester) async {
    app.main(); // Mở ứng dụng

    // Chờ trang đăng ký hiển thị
    await tester.pumpAndSettle();

    // Tìm và điền thông tin đăng ký
    final usernameField =
        find.byKey(Key('username_field')); // Trường cho username
    final passwordField =
        find.byKey(Key('password_field')); // Trường cho password
    final emailField = find.byKey(Key('email_field')); // Trường cho email
    final submitButton = find.byKey(Key('submit_button')); // Nút đăng ký

    // Điền thông tin đăng ký (bao gồm username, email, password)
    await tester.enterText(usernameField, 'caohieu');
    await tester.enterText(passwordField, 'caohieu241210@gmail.com');
    await tester.enterText(emailField, 'hieu@1010');
    await tester.tap(submitButton);
    await tester.pumpAndSettle(); // Chờ trang cập nhật

    // Kiểm tra đăng ký thành công
    expect(find.text('Đăng ký thành công'), findsOneWidget);

    // Chuyển đến trang đăng nhập
    final loginButton = find.byKey(Key('login_button'));
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Điền thông tin đăng nhập (chỉ có email và password)
    await tester.enterText(emailField, 'testuser@example.com');
    await tester.enterText(passwordField, 'testpassword');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Kiểm tra đăng nhập thành công
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
  });
}
