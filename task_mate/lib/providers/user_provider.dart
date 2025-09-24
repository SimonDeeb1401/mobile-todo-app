import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _mode = "createdAt"; // Default sort mode
  String _order = "asc"; // Default sort order

  String get mode => _mode;
  String get order => _order;

  UserProvider() {
    _fetchSortPreference();
  }
  
  Future<void> _fetchSortPreference() async {
    try {
      final pref = await ApiService.getSortPreference();
      if (pref != null) {
        _mode = pref['mode'] ?? "createdAt";
        _order = pref['order'] ?? "asc";
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sort preference: $e');
      }
    }
  }

  Future<List<dynamic>?> updateSortPreference(BuildContext context, String mode, String order) async {
    try {
      final tasks = await ApiService.updateSortPreference(mode, order);
      if (tasks != null) {
        _mode = mode;
        _order = order;
        notifyListeners();
        return tasks;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating sort preference: $e');
      }
      return null;
    }
  }
}
