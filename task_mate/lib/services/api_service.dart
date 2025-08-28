import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
const String baseUrl = "http://localhost:5000/api";

class ApiService {
  // Signup
  static Future<bool> signup(String email, String password) async {
    final res = await http.post(Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}));
    return res.statusCode == 201;
  }

  // Login
  static Future<bool> login(String email, String password) async {
    final res = await http.post(Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}));
    if (res.statusCode == 200) {
      final token = jsonDecode(res.body)["token"];
      await storage.write(key: "jwt", value: token);
      return true;
    }
    return false;
  }

  // Get user items
  static Future<List<dynamic>> getItems() async {
    final token = await storage.read(key: "jwt");
    final res = await http.get(Uri.parse("$baseUrl/items"),
        headers: {"Authorization": "Bearer $token"});
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to fetch items");
    }
  }

  // Add an item
  static Future<bool> createItem(String title) async {
    final token = await storage.read(key: "jwt");
    final res = await http.post(Uri.parse("$baseUrl/items"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"title": title}));
    return res.statusCode == 201;
  }
}
