import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_mate/providers/user_provider.dart';
import 'dart:async';
import 'add_task.dart';
import '../providers/task_provider.dart';
import 'edit_tasks.dart';
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
  // bool _hasInitialized = false;

  TaskProvider? _taskProvider;

  TabController get tabController => _tabController;
  TextEditingController get searchController => _searchController;
  Timer? get debounce => _debounce;
  bool get isSearching => _isSearching;

  Future<void> _fetchTasks() async {
    await _taskProvider?.fetchTasks();
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch tasks when the screen initializes
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _fetchTasks();
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //if (_taskProvider == null) {  // Only initialize once
      _taskProvider = Provider.of<TaskProvider>(context, listen: false);
      _taskProvider?.setTabController(_tabController);
    //}
    // if (_hasInitialized) return;
    // _hasInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTasks();
    });
  }

  @override
  void dispose() {
    _taskProvider?.clearTabController();
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

  void _showCommentsBottomSheet(BuildContext context, String taskId, List<String> comments) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // So keyboard doesn't hide the text field
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Comments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(comments[index]),
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () {
                      final newComment = commentController.text.trim();
                      if (newComment.isNotEmpty) {
                        // Add comment logic (e.g., send to Firestore)
                        _taskProvider?.addCommentToTask(taskId, newComment);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }


  // Helper to produce an uppercase initial for an entry like "Name (Occupation)".
  String _initialForEntry(String entry) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) return '';
    final name = trimmed.split('(').first.trim(); // handle "Name (Occupation)"
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : name;
    return first.isNotEmpty ? first[0].toUpperCase() : '';
  }

  // Parse teamText into a list of maps {name, occupation}
  List<Map<String, String>> _parseTeamEntries(String teamText) {
    if (teamText.trim().isEmpty) return [];
    final lines = teamText
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return lines.map((line) {
      final namePart = line.split('(').first.trim();
      String occupation = '';
      final occMatch = RegExp(r'\((.*)\)').firstMatch(line);
      if (occMatch != null && occMatch.groupCount >= 1) {
        occupation = occMatch.group(1)!.trim();
      }
      return {'name': namePart, 'occupation': occupation};
    }).toList();
  }

  // Build a list of member row widgets for the Column
  List<Widget> _buildMemberRows(String teamText, BuildContext context) {
    final members = _parseTeamEntries(teamText);
    return members.map((m) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                _initialForEntry(m['name'] ?? ''),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['name'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  if ((m['occupation'] ?? '').isNotEmpty)
                    Text(
                      m['occupation'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks, TaskProvider taskProvider, int tabIndex) {
    if (tasks.isEmpty) {
      // Show different text depending on which tab is active
      return Center(
        child: Text(
          tabIndex == 0
          ? 'No pending tasks available.'
          : tabIndex == 1
          ? 'No completed tasks available.'
          : 'No shared tasks available.',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Get current sort preferences and fetch with those
        // final userProvider = Provider.of<UserProvider>(context, listen: false);
        // final sortedTasks = await ApiService.updateSortPreference(
        //   userProvider.mode, 
        //   userProvider.order
        // );
        // if (sortedTasks != null) {
        //   taskProvider.setTasks(sortedTasks);
        // }
        _fetchTasks();
      },
      child: (Provider.of<UserProvider>(context).mode != "manual")
      ? ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          // Ensure provider is subscribed to collaborators stream for this task so snapshot is kept up-to-date
          if (_taskProvider != null) _taskProvider!.subscribeToCollaboratorsStream(task['_id']);

          // Read synchronous cached snapshot
          final teamData = taskProvider.getCollaboratorsSnapshot(task['_id']);
          print("Team data for task ${task['_id']}: $teamData");
          String teamText = '';
          if (teamData != null && teamData['user'] != null) {
            final user = teamData['user'];
            final collaborators = teamData['collaborators'] as List? ?? [];
            final userName = user['name'] ?? '';
            final userOccupation = user['occupation'] ?? '';
            final collaboratorsText = collaborators.map((e) => (e['name'] != null && e['occupation'] != null) ? "${e['name']} (${e['occupation']})" : "").join('\n');
            teamText = "$userName ($userOccupation)\n$collaboratorsText";
          }

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
                  task['collaborators'] != null && (task['collaborators'] as List).isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _showCommentsBottomSheet(context, task['_id'], task['comments'] != null ? List<String>.from(task['comments']) : []);
                      },
                      icon: const Icon(Icons.comment, color: AppColors.primary),
                    )
                  : const SizedBox.shrink(),
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
                      taskCollaborators: task['collaborators'] != null ? List<String>.from(task['collaborators']) : [],
                      ),
                    ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  ),
                ],
                ),

                task['collaborators'] != null && (task['collaborators'] as List).isNotEmpty
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildMemberRows(teamText, context),
                    )
                  )
                : tabIndex == 2 ? SizedBox(child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink(),

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
                    // Ensure provider is subscribed to collaborators stream for this task so snapshot is kept up-to-date
                    if (_taskProvider != null) _taskProvider!.subscribeToCollaboratorsStream(task['_id']);

                    // Read synchronous cached snapshot
                    final teamData = taskProvider.getCollaboratorsSnapshot(task['_id']);
                    print("Team data for task ${task['_id']}: $teamData");
                    String teamText = '';
                    if (teamData != null && teamData['user'] != null) {
                      final user = teamData['user'];
                      final collaborators = teamData['collaborators'] as List? ?? [];
                      final userName = user['name'] ?? '';
                      final userOccupation = user['occupation'] ?? '';
                      final collaboratorsText = collaborators.map((e) => (e['name'] != null && e['occupation'] != null) ? "${e['name']} (${e['occupation']})" : "").join('\n');
                      teamText = "$userName ($userOccupation)\n$collaboratorsText";
                    }

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
                                taskCollaborators: task['collaborators'] != null ? List<String>.from(task['collaborators']) : [],
                                ),
                              ),
                              );
                            },
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            ),
                          ],
                          ),

                          task['collaborators'] != null && (task['collaborators'] as List).isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildMemberRows(teamText, context),
                              )
                            )
                          : tabIndex == 2 ? SizedBox(child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink(),

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

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        // Filter tasks into completed and incomplete
        List<Map<String, dynamic>> incompleteTasks = tasks.where((task) => !(task['completed'] ?? false) && (task['collaborators'] == null || (task['collaborators'] as List).isEmpty)).cast<Map<String, dynamic>>().toList();
        List<Map<String, dynamic>> completedTasks = tasks.where((task) => (task['completed'] ?? false) && (task['collaborators'] == null || (task['collaborators'] as List).isEmpty)).cast<Map<String, dynamic>>().toList();
        List<Map<String, dynamic>> sharedTasks = tasks.where((task) => task['collaborators'] != null && (task['collaborators'] as List).isNotEmpty).cast<Map<String, dynamic>>().toList();

        return Scaffold(
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
                        _buildTaskList(incompleteTasks, taskProvider, 0),
                        _buildTaskList(completedTasks, taskProvider, 1),
                        _buildTaskList(sharedTasks, taskProvider, 2),
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