import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<dynamic> _tasks = [];
  bool _isLoading = false;

  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;

  void setTasks(List<dynamic> tasks) {
    _tasks = List.from(tasks);
    notifyListeners();
  }

  Future<void> fetchTasksSorted() async {
    try {
      final sortPreference = await ApiService.getSortPreference();
      final sortedTasks = await ApiService.updateSortPreference(
        sortPreference?['mode'] ?? "createdAt", 
        sortPreference?['order'] ?? "asc"
      );
      if (sortedTasks != null) {
        setTasks(sortedTasks);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sorted tasks: $e');
      }
    }
  }

  /// Fetch tasks from API
  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getTasks();
      _tasks = List.from(data);
      notifyListeners();
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
      final success = await ApiService.createTask(
        title,
        description,
        priority,
        deadline,
        completed,
      );

      if (success) {
        // Refresh the task list to include the new task
        await fetchTasksSorted();
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
      ApiService.updateCompleteStatus(_tasks[index]['_id'], _tasks[index]['completed']);
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
      final success = await ApiService.updateTask(
        taskId,
        title,
        description,
        priority,
        deadline,
      );

      if (success) {
        // Refresh the task list to include the updated task
        await fetchTasksSorted();
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

  Future<bool> deleteTask(String taskId) async {
    try {
      final success = await ApiService.deleteTask(taskId);
      if (success) {
        // Refresh the task list to remove the deleted task
        await fetchTasksSorted();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting task: $e');
      }
      return false;
    }
  }
}
