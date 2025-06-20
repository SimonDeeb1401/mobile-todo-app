import 'package:flutter/material.dart';

class Task {
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.deadline,
    required this.isCompleted,
  });
}

class TaskListScreen extends StatefulWidget {

  TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<Task> tasks = [
    Task(
      title: 'Buy groceries',
      description: 'Milk, Bread, Eggs, Fruits',
      deadline: DateTime.now().add(Duration(days: 1)),
      isCompleted: false,
    ),
    Task(
      title: 'Finish project',
      description: 'Complete the Flutter UI for the todo app',
      deadline: DateTime.now().add(Duration(days: 2)),
      isCompleted: true,
    ),
    Task(
      title: 'Call Mom',
      description: 'Discuss weekend plans',
      deadline: DateTime.now().add(Duration(days: 3)),
      isCompleted: false,
    ),
    // Add more tasks as needed
  ];

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
              value: task.isCompleted,
              onChanged: (value) {
                setState(() {
                tasks[index] = Task(
                  title: task.title,
                  description: task.description,
                  deadline: task.deadline,
                  isCompleted: value ?? false,
                );
                });
              },
              activeColor: Colors.green,
              ),
              title: Text(task.title),
              subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.description),
                const SizedBox(height: 4),
                Text(
                'Deadline: ${task.deadline.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              ),
              trailing: task.isCompleted
                ? const Icon(Icons.done, color: Colors.green)
                : null,
            ),
            );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add new task functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}