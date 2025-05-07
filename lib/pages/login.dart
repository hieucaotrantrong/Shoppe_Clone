import 'package:flutter/material.dart';
import 'package:food_app/pages/admin/admin_dashboard.dart';
import 'package:food_app/pages/bottomnav.dart';
import 'package:food_app/pages/signup.dart';
import 'package:food_app/widget/widget_support.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFff5c30),
                    Color(0xFFe74b1a),
                  ],
                ),
              ),
            ),
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
              height: MediaQuery.of(context).size.height / 1.5,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        Text(
                          "Welcome Back!",
                          style: AppWidget.headlineTextFeildStyle(),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: AppWidget.semiBoldTextFieldStyle(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        SizedBox(height: 30),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: AppWidget.semiBoldTextFieldStyle(),
                            prefixIcon: Icon(Icons.password_outlined),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(height: 40),
                        _isLoading
                            ? CircularProgressIndicator()
                            : GestureDetector(
                                onTap: () {
                                  _login();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFff5722),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  child: Center(
                                    child: Text(
                                      "LOGIN",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                "Don't have an account?",
                                style: AppWidget.semiBoldTextFieldStyle(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUp(),
                                  ),
                                );
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Color(0xFFff5722),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Kiểm tra kết nối mạng
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không có kết nối mạng. Vui lòng kiểm tra lại.')),
        );
        return;
      }

      try {
        print('Attempting to login with: ${emailController.text}'); // Debug log
        
        final result = await ApiService.login(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (result != null && result['status'] == 'success') {
          // Lưu thông tin người dùng vào SharedPreferences
          await SharedPreferenceHelper().saveUserData(
            result['data']['id'].toString(),
            result['data']['name'],
            result['data']['email'],
            result['data']['role'],
          );
          
          // Lưu URL ảnh đại diện nếu có
          if (result['data']['profile_image'] != null) {
            await SharedPreferenceHelper().saveUserProfile(result['data']['profile_image']);
          }
          
          // Kiểm tra vai trò người dùng
          if (result['data']['role'] == 'admin') {
            // Chuyển đến trang admin dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
            );
          } else {
            // Chuyển đến trang người dùng thông thường
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottomNav()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e')),
        );
      }
    }
  }
}











