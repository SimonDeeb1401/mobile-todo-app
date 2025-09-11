import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'task_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _mode = "createdAt"; // Default sort mode
  String _order = "asc"; // Default sort order

  String get mode => _mode;
  String get order => _order;

  Future<List<dynamic>?> updateSortPreference(BuildContext context, String mode, String order) async {
    try {
      final tasks = await ApiService.updateSortPreference(mode, order);
      if (tasks != null) {
        _mode = mode;
        _order = order;
        print("Tasks WLAAKKK: $tasks");
        // await ApiService.getTasks(); // Refresh tasks after updating preference
        // await Provider.of<TaskProvider>(context, listen: false).fetchTasks();
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
