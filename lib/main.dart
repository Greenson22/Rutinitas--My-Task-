import 'package:flutter/material.dart';
import 'features/task_master/presentation/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';

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
        return WindowControlWrapper(child: child!);
      },
      home: const HomeScreen(),
    );
  }
}

class WindowControlWrapper extends StatelessWidget {
  final Widget child;

  const WindowControlWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // AppBar khusus berukuran kecil (32 pixel) di paling atas
          Container(
            height: 32,
            color:
                Theme.of(context).appBarTheme.backgroundColor ??
                Colors.transparent,
            child: Row(
              children: [
                // Area kosong yang bisa di-drag untuk memindahkan jendela aplikasi
                const Expanded(
                  child: WindowCaption(
                    brightness: Brightness.dark,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                // Deretan tombol kontrol window kustom
                // 1. Tombol Minimize
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.minimize, size: 16),
                  alignment: Alignment.bottomCenter,
                  onPressed: () async {
                    if (await windowManager.isMinimized()) {
                      await windowManager.restore();
                    } else {
                      await windowManager.minimize();
                    }
                  },
                ),
                const SizedBox(width: 12),
                // 2. Tombol Maximize / Restore
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.crop_square, size: 14),
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                ),
                const SizedBox(width: 12),
                // 3. Tombol Close
                InkWell(
                  onTap: () async {
                    await windowManager.close();
                  },
                  hoverColor: Colors.red.withOpacity(0.8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Halaman aplikasi Anda yang sebenarnya akan muncul di bawah AppBar tipis ini
          Expanded(child: child),
        ],
      ),
    );
  }
}
