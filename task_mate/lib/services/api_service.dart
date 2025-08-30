import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Use different URLs for different platforms
String get baseUrl {
  if (Platform.isAndroid) {
    // For Android emulator, use 10.0.2.2 to access host machine
    // For physical device, use your actual IP address
    return "http://10.0.0.9:5000/api"; // Change to 10.0.0.9 if using physical device
  } else if (Platform.isIOS) {
    // For iOS simulator, localhost should work
    return "http://localhost:5000/api";
  }
  // Default fallback
  return "http://10.0.0.9:5000/api";
}

class ApiService {
  // Signup
  static Future<bool> signup(String email, String password) async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/auth/signup"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}));
      return res.statusCode == 201;
    } catch (e) {
      print("Signup error: $e");
      print("Trying to connect to: $baseUrl/auth/signup");
      return false;
    }
  }

  // Login
  static Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/auth/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}));
      if (res.statusCode == 200) {
        final token = jsonDecode(res.body)["token"];
        await storage.write(key: "jwt", value: token);
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      print("Trying to connect to: $baseUrl/auth/login");
      return false;
    }
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
  static Future<bool> createItem(String title, String description, String priority, DateTime deadline, bool completed) async {
    try {
      final token = await storage.read(key: "jwt");
      print("Token: $token");
      print("Creating item with URL: $baseUrl/items");
      
      final res = await http.post(Uri.parse("$baseUrl/items"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({
            "title": title, 
            "description": description, 
            "priority": priority, 
            "deadline": deadline.toIso8601String(), 
            "completed": completed
          }));
      
      print("Response status code: ${res.statusCode}");
      print("Response body: ${res.body}");
      
      return res.statusCode == 201;
    } catch (e) {
      print("CreateItem error: $e");
      print("Trying to connect to: $baseUrl/items");
      return false;
    }
  }
}
