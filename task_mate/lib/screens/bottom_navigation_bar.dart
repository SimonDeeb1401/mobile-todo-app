import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:task_mate/providers/task_provider.dart';
import 'package:task_mate/providers/user_provider.dart';
import 'package:task_mate/screens/tasks_screen.dart';
import '../theme/app_theme.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final int initialIndex;

  const BottomNavigationBarScreen({super.key, this.initialIndex = 0});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  //final GlobalKey<State<TaskListScreen>> _taskScreenKey = GlobalKey<State<TaskListScreen>>();
  int _currentIndex = 0;

  //late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  // void Function() _startSearch = () {};
  // void Function() _stopSearch = () {};
  // void Function(String) _onSearchChanged = (query) {};
  // Future<void> Function(String) _applySearch = (query) async {};
  // void Function(BuildContext context, String currentSort, bool isAscending) _showSortDialog = (context, currentSort, isAscending) {};
  // Future<Map<String,dynamic>?> Function(BuildContext context,{List<String> initialPriorities, String? initialDeadline}) _showFilterBottomSheet = (context, {initialPriorities = const [], initialDeadline}) async {return null;};

  late final List<Widget> _screens = [
    // TaskListScreen(onControllerReady: (controller) {
    //   _tabController = controller.tabController;
    //   _searchController = controller.searchController;
    //   _debounce = controller.debounce;
    //   _isSearching = controller.isSearching;
    //   _startSearch = controller.startSearch;
    //   _stopSearch = controller.stopSearch;
    //   _onSearchChanged = controller.onSearchChanged;
    //   _applySearch = controller.applySearch;
    //   _showSortDialog = controller.showSortDialog;
    //   _showFilterBottomSheet = controller.showFilterBottomSheet;
    // }),
    TaskListScreen(),
    Container(color: AppColors.primary),
    // ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    //_tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    //_tabController.dispose();
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
        List<Map<String, dynamic>> incompleteTasks = tasks.where((task) => !(task['completed'] ?? false)).cast<Map<String, dynamic>>().toList();
        List<Map<String, dynamic>> completedTasks = tasks.where((task) => task['completed'] ?? false).cast<Map<String, dynamic>>().toList();

        final currentSort = userProvider.mode;
        final isAscending = userProvider.order == "asc";

        //_tabController = taskProvider.tabController;
        _searchController = taskProvider.searchController;
        _debounce = taskProvider.debounce;
        _isSearching = taskProvider.isSearching;
        //final taskScreenState = _taskScreenKey.currentState;
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