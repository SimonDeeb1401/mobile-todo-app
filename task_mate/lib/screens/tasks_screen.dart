import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_task.dart';
import '../providers/task_provider.dart';
import 'edit_tasks.dart';

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
                            child: ListTile(
                              leading: Checkbox(
                                value: task['completed'] ?? false,
                                onChanged: (value) {
                                  taskProvider.toggleTaskCompletion(index);
                                },
                              ),
                              title: Text(task['title'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task['description'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text('Priority: ${task['priority'] ?? ''}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Deadline: ${task['deadline'] != null ? DateTime.parse(task['deadline']).toLocal().toString().split(' ')[0] : 'N/A'}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              // trailing: (task['completed'] ?? false)
                              //     ? Icon(Icons.done, color: Theme.of(context).primaryColor)
                              //     : null,
                              trailing: IconButton(
                                onPressed: () {
                                  // Navigate to EditTaskScreen
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