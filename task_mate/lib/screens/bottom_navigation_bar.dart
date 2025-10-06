import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:task_mate/providers/task_provider.dart';
import 'package:task_mate/providers/user_provider.dart';
import 'package:task_mate/screens/tasks_screen.dart';
import 'package:task_mate/screens/profile_screen.dart';
import '../theme/app_theme.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final int initialIndex;

  const BottomNavigationBarScreen({super.key, this.initialIndex = 0});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentIndex = 0;

  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  late final List<Widget> _screens = [
    TaskListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, TaskProvider>(
      builder: (context, userProvider, taskProvider, child) {
        final tasks = taskProvider.tasks;
        // Filter tasks into completed and incomplete
        List<Map<String, dynamic>> incompleteTasks = tasks.where((task) => !(task['completed'] ?? false) && (task['collaborators'] == null || (task['collaborators'] as List).isEmpty)).cast<Map<String, dynamic>>().toList();
        List<Map<String, dynamic>> completedTasks = tasks.where((task) => (task['completed'] ?? false) && (task['collaborators'] == null || (task['collaborators'] as List).isEmpty)).cast<Map<String, dynamic>>().toList();
        List<Map<String, dynamic>> sharedTasks = tasks.where((task) => task['collaborators'] != null && (task['collaborators'] as List).isNotEmpty).cast<Map<String, dynamic>>().toList();

        final currentSort = userProvider.mode;
        final isAscending = userProvider.order == "asc";

        
        _searchController = taskProvider.searchController;
        _debounce = taskProvider.debounce;
        _isSearching = taskProvider.isSearching;
        
        return Scaffold(
          appBar: AppBar(
            title: !_isSearching
              ? Text('TaskMate', style: AppTextStyles.heading3.copyWith(color: AppColors.primary))
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
                      taskProvider.applySearch(context, "");
                    },
                  )
                ),
                onChanged: (value) => taskProvider.onSearchChanged(context, value),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => taskProvider.applySearch(context, v),
              ),
            automaticallyImplyLeading: false,
            actions: _currentIndex == 0 ? [
              !_isSearching
                ? IconButton(icon: const Icon(Icons.search, color: AppColors.primary), onPressed: taskProvider.startSearch)
                : IconButton(icon: const Icon(Icons.close, color: AppColors.primary), onPressed: () => taskProvider.stopSearch(context)),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primary),
                onPressed: () {
                  // Open filter bottom sheet
                  taskProvider.showFilterBottomSheet(context, initialPriorities: [], initialDeadline: null);
                },
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert, color: AppColors.primary),
                onPressed: () {
                  // Open sort dialog
                  taskProvider.showSortDialog(context, currentSort, isAscending);
                },
              ),
            ] : null,
            bottom: _currentIndex == 0 && taskProvider.tabController != null ? TabBar(
              controller: taskProvider.tabController!,
              tabs: [
                Tab(
                  text: 'Pending (${incompleteTasks.length})',
                  icon: const Icon(Icons.pending_actions),
                ),
                Tab(
                  text: 'Completed (${completedTasks.length})',
                  icon: const Icon(Icons.check_circle),
                ),
                Tab(
                  text: 'Shared (${sharedTasks.length})',
                  icon: const Icon(Icons.people_alt_rounded),
                ),
              ],
            ) : null,
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              )
            ],
          ),
        );
      }
    );
  }
}