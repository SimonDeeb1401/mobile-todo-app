import 'package:flutter/material.dart';
import 'add_task.dart';
import '../services/api_service.dart';

class TaskListScreen extends StatefulWidget {

  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List tasks = [];
  
  void fetchTasks() async {
    final data = await ApiService.getItems();
    setState(() => tasks = data);
  }

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
            return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: Checkbox(
              value: task['completed'] ?? false,
              onChanged: (value) {
                setState(() {
                task['completed'] = value ?? false;
                });
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
              trailing: (task['completed'] ?? false)
                ? Icon(Icons.done, color: Theme.of(context).primaryColor)
                : null,
            ),
            );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle adding a new task
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          ).then((result) {
            if (result == true) {
              // Refresh the task list if a new task was added
              setState(() {});
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}