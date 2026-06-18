// lib/main.dart

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'features/task_master/presentation/screens/task_master_screen.dart';
import 'features/task_master/presentation/widgets/password_gate.dart'; // Import berkas baru Anda disini

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
      builder: (context, child) {
        final platform = Theme.of(context).platform;

        if (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux) {
          return WindowControlWrapper(child: child!);
        }

        return child!;
      },
      // Menggunakan PasswordGate yang kini berasal dari file terpisah
      home: const PasswordGate(child: HomeScreen()),
    );
  }
}

class WindowControlWrapper extends StatelessWidget {
  final Widget child;

  const WindowControlWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Color barColor = Colors.indigo;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Container(
            height: 30,
            color: barColor,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      windowManager.startDragging();
                    },
                    child: const SizedBox(height: double.infinity),
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 45,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.minimize,
                            size: 16,
                            color: Colors.white,
                          ),
                          hoverColor: Colors.white.withOpacity(0.1),
                          onPressed: () async {
                            if (await windowManager.isMinimized()) {
                              await windowManager.restore();
                            } else {
                              await windowManager.minimize();
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: 45,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.crop_square,
                            size: 14,
                            color: Colors.white,
                          ),
                          hoverColor: Colors.white.withOpacity(0.1),
                          onPressed: () async {
                            if (await windowManager.isMaximized()) {
                              await windowManager.unmaximize();
                            } else {
                              await windowManager.maximize();
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: 45,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          hoverColor: Colors.redAccent,
                          onPressed: () async {
                            await windowManager.close();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
