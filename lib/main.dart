import 'package:flutter/material.dart';
import 'features/task_master/presentation/screens/home_screen.dart';

void main() {
  runApp(const TaskMasterApp());
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'My Tasks',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: false),
      home: const HomeScreen(),
    );
  }
}
