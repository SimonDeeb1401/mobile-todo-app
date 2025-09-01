import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_task.dart';
import '../providers/task_provider.dart';
import 'edit_tasks.dart';
import '../theme/app_theme.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch tasks when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Tasks'),
          ),
          body: taskProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : taskProvider.tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet. Add your first task!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: taskProvider.fetchTasks,
                      child: ListView.builder(
                        itemCount: taskProvider.tasks.length,
                        itemBuilder: (context, index) {
                          final task = taskProvider.tasks[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                children: [
                                  // Checkbox(
                                  // value: task['completed'] ?? false,
                                  // onChanged: (value) {
                                  //   taskProvider.toggleTaskCompletion(index);
                                  // },
                                  // ),
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
                                      taskProvider.toggleTaskCompletion(index);
                                    },
                                    icon: const Icon(Icons.check),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      //taskProvider.deleteTask(index);
                                    },
                                    icon: const Icon(Icons.delete),
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
                                  icon: const Icon(Icons.edit),
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
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.black),
                                      ),
                                      child: Text(
                                        'Deadline: ${task['deadline'] != null ? DateTime.parse(task['deadline']).toLocal().toString().split(' ')[0] : 'N/A'}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.black),
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