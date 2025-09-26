import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_mate/providers/user_provider.dart';
import 'package:task_mate/services/api_service.dart';
import 'dart:async';
import 'add_task.dart';
import '../providers/task_provider.dart';
import 'edit_tasks.dart';
import 'login_screen.dart';
import '../theme/app_theme.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch tasks when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  Widget _buildTaskList(List<Map<String, dynamic>> tasks, TaskProvider taskProvider, bool isPendingTab) {
    if (tasks.isEmpty) {
      // Show different text depending on which tab is active
      return Center(
        child: Text(
          isPendingTab
          ? 'No pending tasks available.'
          : 'No completed tasks available.',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Get current sort preferences and fetch with those
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final sortedTasks = await ApiService.updateSortPreference(
          userProvider.mode, 
          userProvider.order
        );
        if (sortedTasks != null) {
          taskProvider.setTasks(sortedTasks);
        }
      },
      child: (Provider.of<UserProvider>(context).mode != "manual")
      ? ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                children: [
                  Expanded(
                  child: Text(
                    task['title'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: (task['completed'] ?? false)
                      ? TextDecoration.lineThrough
                      : null,
                    ),
                  ),
                  ),
                  IconButton(
                    onPressed: () {
                      final originalIndex = taskProvider.tasks.indexWhere((t) => t['_id'] == task['_id']);
                      if (originalIndex != -1) {
                        taskProvider.toggleTaskCompletion(originalIndex);
                      }
                    },
                    icon: (task['completed'] ?? false)
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.check_circle, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure you want to delete this task?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await taskProvider.deleteTask(task['_id']);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                  IconButton(
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskScreen(
                      taskId: task['_id'],
                      taskTitle: task['title'],
                      taskDescription: task['description'],
                      taskDeadline: DateTime.parse(task['deadline']),
                      taskPriority: task['priority'],
                      ),
                    ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  ),
                ],
                ),
                const SizedBox(height: 8),
                if (task['description'] != null && task['description'].toString().isNotEmpty)
                Text(
                  task['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task['priority'] ?? 'N/A'),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(
                        'Priority: ${task['priority'] ?? 'N/A'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: (task['priority'] == 'low') ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(
                        'Deadline: ${task['deadline'] != null ? DateTime.parse(task['deadline']).toLocal().toString().split(' ')[0] : 'N/A'}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
                      ),
                    ),
                  ),
                ],
                ),
              ],
              ),
            ),
          );
        },
      )
      : Stack(
        children: [
          AbsorbPointer(
            absorbing: taskProvider.isAnyTaskMoving, // Disable all touches when loading
            child: Opacity(
                opacity: taskProvider.isAnyTaskMoving ? 0.6 : 1.0, // Subtle dimming when disabled
                child: ReorderableListView.builder(
                  itemCount: tasks.length,
                  onReorder: (oldOrderIndex, newOrderIndex) async {
                    // Validate indices before reordering
                    if (oldOrderIndex < 0 || oldOrderIndex >= tasks.length || 
                        newOrderIndex < 0 || newOrderIndex > tasks.length) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid reorder operation"))
                      );
                      return;
                    }
                    
                    final moved = tasks[oldOrderIndex];
                
                    // // Calculate global indices in the full task list
                    // final allTasks = taskProvider.tasks;
                    // final globalOldIndex = allTasks.indexWhere((task) => task['_id'] == moved['_id']);
                    
                    // // For newIndex, we need to find where this position maps in the global list
                    // int globalNewIndex;
                    // if (newOrderIndex >= tasks.length) {
                    //   // Moving to end of this filtered list
                    //   globalNewIndex = allTasks.length - 1;
                    // } else {
                    //   final targetTask = tasks[newOrderIndex > oldOrderIndex ? newOrderIndex - 1 : newOrderIndex];
                    //   globalNewIndex = allTasks.indexWhere((task) => task['_id'] == targetTask['_id']);
                    // }
                
                    // Move task locally with ReorderableListView indices
                    taskProvider.moveTaskLocally(oldOrderIndex, newOrderIndex);
                    
                    try {
                      // For server call, we need the final position after the local move
                      // Calculate the actual final index
                        int finalIndex = newOrderIndex;
                        if (newOrderIndex > oldOrderIndex) {
                          finalIndex = newOrderIndex - 1;
                        }
                        finalIndex = finalIndex.clamp(0, tasks.length - 1);
                
                      await taskProvider.moveTaskOnServer(moved['_id'], finalIndex);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to reorder tasks"))
                      );
                    }
                  },
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      key: ValueKey(task['_id']),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                          children: [
                            Expanded(
                            child: Text(
                              task['title'] ?? '',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: (task['completed'] ?? false)
                                ? TextDecoration.lineThrough
                                : null,
                              ),
                            ),
                            ),
                            IconButton(
                              onPressed: () {
                                final originalIndex = taskProvider.tasks.indexWhere((t) => t['_id'] == task['_id']);
                                if (originalIndex != -1) {
                                  taskProvider.toggleTaskCompletion(originalIndex);
                                }
                              },
                              icon: (task['completed'] ?? false)
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.check_circle, color: Colors.grey),
                            ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Delete Task'),
                                      content: const Text('Are you sure you want to delete this task?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await taskProvider.deleteTask(task['_id']);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                            IconButton(
                            onPressed: () {
                              Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTaskScreen(
                                taskId: task['_id'],
                                taskTitle: task['title'],
                                taskDescription: task['description'],
                                taskDeadline: DateTime.parse(task['deadline']),
                                taskPriority: task['priority'],
                                ),
                              ),
                              );
                            },
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            ),
                          ],
                          ),
                          const SizedBox(height: 8),
                          if (task['description'] != null && task['description'].toString().isNotEmpty)
                          Text(
                            task['description'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(task['priority'] ?? 'N/A'),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Text(
                                  'Priority: ${task['priority'] ?? 'N/A'}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: (task['priority'] == 'low') ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Text(
                                  'Deadline: ${task['deadline'] != null ? DateTime.parse(task['deadline']).toLocal().toString().split(' ')[0] : 'N/A'}',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                          ),
                        ],
                      )));
                    },
                  ),
                ),
          ),

          if (taskProvider.isAnyTaskMoving)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Moving task...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]
        ),
      );
  }

  void _showSortDialog(BuildContext context, String currentSort, bool isAscending) {
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

  Future<Map<String,dynamic>?> _showFilterBottomSheet(BuildContext context,{List<String> initialPriorities = const [], String? initialDeadline}) {
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

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    _searchController.clear();
    _applySearch("");
    setState(() => _isSearching = false);
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applySearch(q);
    });
  }

  Future<void> _applySearch(String q) async {
    final trimmed = q.trim();
    if (trimmed.length >= 2) {
      await Provider.of<TaskProvider>(context, listen: false).fetchSearchResults(search: trimmed);
    } else if (trimmed.isEmpty) {
      await Provider.of<TaskProvider>(context, listen: false).fetchTasksSorted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, TaskProvider>(
      builder: (context, userProvider, taskProvider, child) {
        final tasks = taskProvider.tasks;
        // Filter tasks into completed and incomplete
        List<Map<String, dynamic>> incompleteTasks = tasks.where((task) => !(task['completed'] ?? false)).cast<Map<String, dynamic>>().toList();
        List<Map<String, dynamic>> completedTasks = tasks.where((task) => task['completed'] ?? false).cast<Map<String, dynamic>>().toList();

        final currentSort = userProvider.mode;
        final isAscending = userProvider.order == "asc";
        return Scaffold(
          appBar: AppBar(
            title: !_isSearching 
              ? Text('My Tasks', style: AppTextStyles.heading3.copyWith(color: AppColors.primary))
              : TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _applySearch("");
                      },
                    )
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => _applySearch(v),
                ),
            automaticallyImplyLeading: false,
            actions: [
              !_isSearching
                ? IconButton(icon: const Icon(Icons.search, color: AppColors.primary), onPressed: _startSearch)
                : IconButton(icon: const Icon(Icons.close, color: AppColors.primary), onPressed: _stopSearch),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primary),
                onPressed: () {
                  // Open filter bottom sheet
                  _showFilterBottomSheet(context, initialPriorities: [], initialDeadline: null);
                },
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert, color: AppColors.primary),
                onPressed: () {
                  // Open sort dialog
                  _showSortDialog(context, currentSort, isAscending);
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.primary),
                onPressed: () async {
                  final success = await ApiService.logout();
                  if (success) {
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logout failed. Please try again.')),
                    );
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'Pending (${incompleteTasks.length})',
                  icon: const Icon(Icons.pending_actions),
                ),
                Tab(
                  text: 'Completed (${completedTasks.length})',
                  icon: const Icon(Icons.check_circle),
                ),
              ],
            ),
          ),
          body: taskProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : taskProvider.tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks yet. Add your first task!',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTaskList(incompleteTasks, taskProvider, true),
                        _buildTaskList(completedTasks, taskProvider, false),
                      ],
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              // Navigate to AddTaskScreen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTaskScreen(),
                ),
              );
              // No need to manually refresh since the provider will handle it
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}