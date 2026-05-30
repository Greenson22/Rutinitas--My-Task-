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
        // Cek apakah aplikasi berjalan di platform desktop (Windows, macOS, Linux)
        // Kita gunakan Theme.of(context).platform untuk mendeteksi platform saat runtime
        final platform = Theme.of(context).platform;

        if (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux) {
          // Jika di desktop, tampilkan window control wrapper khusus desktop
          return WindowControlWrapper(child: child!);
        }

        // Jika di Android, iOS, atau Web, langsung kembalikan child tanpa wrapper desktop
        return child!;
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
    // Mengambil warna tema AppBar utama agar menyatu secara visual
    final Color barColor = Colors.indigo;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // 1. BAR KONTROL JENDELA UTAMA (Paling Atas)
          Container(
            height: 30, // Ukuran bar yang tipis dan minimalis
            color: barColor,
            child: Row(
              children: [
                // Area kosong kiri sampai tengah yang bisa digunakan untuk menggeser/drag aplikasi
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      windowManager.startDragging();
                    },
                    child: const SizedBox(height: double.infinity),
                  ),
                ),
                // Wadah khusus tombol kontrol di pojok kanan agar ukuran & posisinya presisi
                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Minimize
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
                      // Tombol Maximize / Restore
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
                      // Tombol Close
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
                          hoverColor: Colors
                              .redAccent, // Berubah merah saat kursor menyentuh tombol close
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
          // 2. HALAMAN APLIKASI UTAMA (Muncul tepat di bawah bar kontrol)
          Expanded(child: child),
        ],
      ),
    );
  }
}
