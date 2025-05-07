import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL cơ sở của API
  final String baseUrl = 'http://localhost:3001/api';
  
  // GET tất cả các món ăn
  Future<List<dynamic>> getFoodItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/food-items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load food items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting food items: $e');
      throw e;
    }
  }
  
  // GET một món ăn theo ID
  Future<dynamic> getFoodItem(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/food-items/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load food item: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting food item: $e');
      throw e;
    }
  }
  
  // Đăng nhập
  Future<dynamic> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error signing in: $e');
      throw e;
    }
  }
  
  // Đăng ký
  Future<dynamic> signUp(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body)['data'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error signing up: $e');
      throw e;
    }
  }
}

