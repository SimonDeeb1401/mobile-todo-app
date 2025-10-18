import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:task_mate/providers/user_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TaskProvider extends ChangeNotifier {
  List<dynamic> _tasks = [];
  bool _isLoading = false;
  bool _isAnyTaskMoving = false;
  TabController? _tabController;
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isAnyTaskMoving => _isAnyTaskMoving;
  TabController? get tabController => _tabController;
  TextEditingController get searchController => _searchController;
  Timer? get debounce => _debounce;
  bool get isSearching => _isSearching;

  TaskProvider() {
    _isLoading = true;
    notifyListeners();
  }

  void setTasks(List<dynamic> tasks) {
    _tasks = List.from(tasks);
    notifyListeners();
  }

  void setTabController(TabController controller) {
    _tabController = controller;
    //notifyListeners();
  }

  void clearTabController() {
  _tabController = null;
  //notifyListeners(); // Uncomment if needed for UI updates
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
      //notifyListeners();
      await fetchTasksSorted();
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
    List<String>? collaborators,
  }) async {
    try {
      final success = await ApiService.createTask(
        title,
        description,
        priority,
        deadline,
        completed,
        collaborators,
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
  void toggleTaskCompletion(int index) async {
    if (index >= 0 && index < _tasks.length) {
      _isAnyTaskMoving = true;
      notifyListeners();

      _tasks[index]['completed'] = !(_tasks[index]['completed'] ?? false);
      notifyListeners();
      // final success = await ApiService.updateCompleteStatus(_tasks[index]['_id'], _tasks[index]['completed']);
      // if (success) {
      //   await fetchTasksSorted();
      // }
      final orderIndex = _tasks[index]['orderIndex'] ?? 0;
      await ApiService.updateCompleteStatus(_tasks[index]['_id'], _tasks[index]['completed'], orderIndex: orderIndex);
      notifyListeners();
      await fetchTasksSorted();

      await Future.delayed(const Duration(seconds: 1));
      _isAnyTaskMoving = false;
      notifyListeners();
    } else {
      if (kDebugMode) {
        print('Invalid index for toggleTaskCompletion: $index, tasks length: ${_tasks.length}');
      }
    }
  }

  /// Edit an existing task
  Future<bool> editTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime? deadline,
    required String priority,
    required List<String> collaborators,
  }) async {
    try {
      final success = await ApiService.updateTask(
        taskId,
        title,
        description,
        priority,
        deadline,
        collaborators,
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

  void moveTaskLocally(int oldOrderIndex, int newOrderIndex){
    // Validate indices before performing operations
    if (oldOrderIndex < 0 || oldOrderIndex >= _tasks.length || newOrderIndex < 0 || newOrderIndex > _tasks.length) {
      if (kDebugMode) {
        print('Invalid oldOrderIndex: $oldOrderIndex, tasks length: ${_tasks.length}');
      }
      return;
    }

    // Ensure newOrderIndex is within valid bounds for insertion
    //newOrderIndex = newOrderIndex.clamp(0, _tasks.length);
    
    final task = _tasks.removeAt(oldOrderIndex);
    
    // After removal, adjust the insertion index if needed
    final insertIndex = newOrderIndex > oldOrderIndex ? newOrderIndex - 1 : newOrderIndex;
    
    _tasks.insert(insertIndex, task);
    notifyListeners();
  }

  Future<void> moveTaskOnServer(String taskId, int newOrderIndex) async {
    try {
      _isAnyTaskMoving = true;
      notifyListeners();

      final response = await ApiService.moveTask(taskId, newOrderIndex);
      if (response == null || response['tasks'] == null) {
        if (kDebugMode) {
          print('Failed to move task on server: $taskId to index $newOrderIndex');
        }
        return;
      }
      setTasks(response['tasks']);
      await Future.delayed(const Duration(seconds: 1));
      print("Tasks after move from server: $_tasks");
      //notifyListeners();
      //await fetchTasksSorted();
    } catch (e) {
      if (kDebugMode) {
        print('Error moving task on server: $e');
      }
    } finally {
      _isAnyTaskMoving = false;
      notifyListeners();
    }
  }

  Future<void> fetchSearchResults({required String search}) async {
    await fetchTasksSorted();
    setTasks(_tasks.where((task) => task['title'].toString().toLowerCase().contains(search.toLowerCase()) || task['description'].toString().toLowerCase().contains(search.toLowerCase())).toList());
    notifyListeners();
  }

  Color? _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.lightGreenAccent;
      default:
        return AppColors.primary;
    }
  }

  void showSortDialog(BuildContext context, String currentSort, bool isAscending) {
    showDialog(
      context: context,
      builder: (context) {
        late String selectedSort = currentSort;
        late bool ascending = isAscending;

        return AlertDialog(
          title: const Text("Sort Tasks"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text("Priority"),
                    value: "priority",
                    groupValue: selectedSort,
                    onChanged: (value) {
                      setState(() => selectedSort = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Deadline"),
                    value: "deadline",
                    groupValue: selectedSort,
                    onChanged: (value) {
                      setState(() => selectedSort = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Creation Date"),
                    value: "createdAt",
                    groupValue: selectedSort,
                    onChanged: (value) {
                      setState(() => selectedSort = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Manual Order"),
                    value: "manual",
                    groupValue: selectedSort,
                    onChanged: (value) {
                      setState(() => selectedSort = value!);
                    },
                  ),

                  
                  const Divider(),

                  SwitchListTile(
                    title: const Text("Ascending Order"),
                    value: ascending,
                    onChanged: (value) {
                      setState(() => ascending = value);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Apply"),
              onPressed: () async {
                // Call your API to update user preference
                final tasks = await Provider.of<UserProvider>(context, listen: false).updateSortPreference(context,selectedSort, ascending ? "asc" : "desc");
                if (tasks != null) {
                  Provider.of<TaskProvider>(context, listen: false).setTasks(tasks);
                }
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String,dynamic>?> showFilterBottomSheet(BuildContext context,{List<String> initialPriorities = const [], String? initialDeadline}) {
    return showModalBottomSheet<Map<String,dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<String> selectedPriorities = List.from(initialPriorities);
        String? selectedDueDate = initialDeadline;
        final List<String> dueDateOptions = ["Today", "This Week", "This Month", "Custom"];

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Filter Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Priority filter
                  const Text("Priority", style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: ["High", "Medium", "Low"].map((priority) {
                      return FilterChip(
                        label: Text(priority),
                        backgroundColor: _getPriorityColor(priority.toLowerCase())?.withOpacity(0.2),
                        selected: selectedPriorities.contains(priority),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedPriorities.add(priority);
                            } else {
                              selectedPriorities.remove(priority);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Deadline filter
                  const Text("Deadline", style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: dueDateOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option),
                        selected: option == "Custom" 
                          ? (selectedDueDate != null && 
                            !["Today", "This Week", "This Month"].contains(selectedDueDate))
                          : selectedDueDate == option,
                        onSelected: (bool value) async {
                          if (option == "Custom" && value) {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedDueDate = picked.toIso8601String());
                            }
                          } else {
                            setState(() => selectedDueDate = value ? option : null);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const Divider(),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: const Text("Reset", style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          await Provider.of<TaskProvider>(context, listen: false).fetchTasksSorted();
                          setState(() {
                            selectedPriorities.clear();
                            selectedDueDate = null;
                          });
                          Navigator.pop(context, {
                            "priorities": selectedPriorities,
                            "deadline": selectedDueDate,
                          });
                        },
                      ),
                      TextButton(
                        child: const Text("Apply"),
                        onPressed: () async {
                          final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                          await taskProvider.fetchTasksSorted();
                          String? filterDeadline = switch (selectedDueDate) {
                            "Today" => DateTime.now().toIso8601String().split('T')[0],
                            "This Week" => DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)).toIso8601String().split('T')[0],
                            "This Month" => DateTime(DateTime.now().year, DateTime.now().month + 1).toIso8601String().split('T')[0],
                            null => null,
                            _ => selectedDueDate?.split('T')[0], // Custom date
                          };
                          taskProvider.setTasks(taskProvider.tasks.where((task) => (selectedPriorities.isEmpty || (task['priority'] != null && 
                            selectedPriorities.contains(task['priority'].toString()[0].toUpperCase() + task['priority'].toString().substring(1)))) && 
                            (filterDeadline == null || DateTime.parse(task['deadline'].toString().split('T')[0]).compareTo(DateTime.parse(filterDeadline)) <= 0)).toList());
                          Navigator.pop(context, {
                            "priorities": selectedPriorities,
                            "deadline": selectedDueDate,
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void startSearch() {
    _isSearching = true;
    notifyListeners();
  }

  void stopSearch(BuildContext context) {
    _searchController.clear();
    applySearch(context, "");
    _isSearching = false;
    notifyListeners();
  }

  void onSearchChanged(BuildContext context, String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      applySearch(context, q);
    });
  }

  Future<void> applySearch(BuildContext context, String q) async {
    final trimmed = q.trim();
    if (trimmed.length >= 2) {
      await Provider.of<TaskProvider>(context, listen: false).fetchSearchResults(search: trimmed);
    } else if (trimmed.isEmpty) {
      await Provider.of<TaskProvider>(context, listen: false).fetchTasksSorted();
    }
  }

  Future<Map<String, dynamic>?> getCollaboratorsData(String taskId) async {
    try {
      final data = await ApiService.getCollaboratorsData(taskId);
      //print("Collaborators data for task $taskId: $data");
      if (data != null) {
        final user = data['user'];
        final collaborators = data['collaborators'];
        if (kDebugMode) {
          print('Collaborators for task $taskId: $collaborators');
        }
        print("User: $user");
        print("Collaborators: $collaborators");
        notifyListeners();
        return {
          "user": user,
          "collaborators": collaborators,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching collaborators for task $taskId: $e');
      }
    }
    return null;
  }
}
