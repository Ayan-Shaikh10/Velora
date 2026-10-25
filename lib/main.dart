
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubits/routine/routine_cubit.dart';
import 'cubits/task/task_cubit.dart';
import 'cubits/task_activity/task_activity_cubit.dart';
import 'cubits/task_group/task_group_cubit.dart';
import 'routes/app_routes.dart';
import 'screens/add_task_screen.dart';
import 'screens/main_screen.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskCubit>(
          create: (_) => TaskCubit()..loadTask(),
        ),
        BlocProvider<TaskGroupCubit>(
          create: (_) => TaskGroupCubit()..loadGroups(),
        ),
        BlocProvider<RoutineCubit>(
          create: (_) => RoutineCubit()..loadToday(),
        ),
        BlocProvider<TaskActivityCubit>(
          create: (_) => TaskActivityCubit(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Student Task Manager',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: AppRoutes.main,
        routes: {
          AppRoutes.main: (context) => MainScreen(),
          AppRoutes.addTask: (context) =>
          const AddTaskScreen(),
        },
      ),
    );
  }
}
