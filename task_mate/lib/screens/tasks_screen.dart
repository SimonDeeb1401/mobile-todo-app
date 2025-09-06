import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_mate/services/api_service.dart';
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
      onRefresh: taskProvider.fetchTasks,
      child: ListView.builder(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Filter tasks into completed and incomplete
        final incompleteTasks = taskProvider.tasks.where((task) => !(task['completed'] ?? false)).cast<Map<String, dynamic>>().toList();
        final completedTasks = taskProvider.tasks.where((task) => task['completed'] ?? false).cast<Map<String, dynamic>>().toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Tasks'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_vert, color: AppColors.primary),
                onPressed: () {
                  // Open sort/filter dialog
                  
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