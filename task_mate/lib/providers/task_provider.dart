import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<dynamic> _tasks = [];
  bool _isLoading = false;

  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;

  /// Fetch tasks from API
  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getItems();
      _tasks = data;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks: $e');
      }
      // You might want to handle errors differently here
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new task
  Future<bool> addTask({
    required String title,
    required String description,
    required String priority,
    required DateTime deadline,
    bool completed = false,
  }) async {
    try {
      final success = await ApiService.createItem(
        title,
        description,
        priority,
        deadline,
        completed,
      );

      if (success) {
        // Refresh the task list to include the new task
        await fetchTasks();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding task: $e');
      }
      return false;
    }
  }

  /// Toggle task completion status
  void toggleTaskCompletion(int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index]['completed'] = !(_tasks[index]['completed'] ?? false);
      notifyListeners();
      // TODO: Update on server as well if you have an update API endpoint
    }
  }

  /// Edit an existing task
  Future<bool> editTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime? deadline,
    required String priority,
  }) async {
    try {
      final success = await ApiService.updateItem(
        taskId,
        title,
        description,
        priority,
        deadline,
      );

      if (success) {
        // Refresh the task list to include the updated task
        await fetchTasks();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error editing task: $e');
      }
      return false;
    }
  }
}
