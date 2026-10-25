import 'package:flutter/material.dart';

import '../database/database_service.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'task_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DatabaseService _databaseService = DatabaseService();
  int selectedIndex = 0;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        isLoading: isLoading,
        onViewTasks: () => setState(() => selectedIndex = 1),
        onViewProgress: () => setState(() => selectedIndex = 2),
      ),
      const TasksScreen(),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
