// lib/main.dart
import 'dart:io'; // DITAMBAHKAN untuk melakukan pengecekan Platform.isAndroid
import 'package:flutter/foundation.dart'; // DITAMBAHKAN untuk mendeteksi kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 1. Tambahkan import AdMob
import 'core/presentation/widgets/task_master_entry.dart';
import 'features/task_master/presentation/widgets/password_gate.dart';

void main() async {
  // 2. Ubah fungsi main menjadi async
  // 3. Pastikan binding Flutter telah diinisialisasi sebelum mengakses native SDK
  WidgetsFlutterBinding.ensureInitialized();

  // 4. PERBAIKAN UTAMA: Hanya inisialisasi SDK AdMob jika berjalan di Android (bukan Linux/Desktop)
  if (!kIsWeb && Platform.isAndroid) {
    await MobileAds.instance.initialize();
  }

  runApp(const TaskMasterApp());
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      // Nama ini yang tampil di daftar aplikasi terakhir (recents) Android.
      title: appFlavor == 'frendy' ? 'MyTasksFrendy' : 'My Tasks',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: false),

      // Menggunakan properti builder untuk membungkus seluruh hierarki navigasi
      builder: (context, child) {
        // Pastikan child tidak null (child di sini adalah Navigator bawaan MaterialApp)
        Widget appNavigator = child!;

        // PERBAIKAN: Langsung teruskan appNavigator ke PasswordGate.
        // Jangan dibungkus dengan Navigator lokal di sini agar tombol Back Android
        // dapat menutup dialog di dalam aplikasi dengan normal.
        Widget secureApp = PasswordGate(child: appNavigator);

        // Evaluasi platform untuk Window Control (Desktop)
        final platform = Theme.of(context).platform;
        if (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux) {
          return WindowControlWrapper(child: secureApp);
        }

        return secureApp;
      },
      home: const TaskMasterEntry(),
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
          Container(
            color: Colors.indigo.shade700,
            height: 30,
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Text(
                  'My Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                WindowCaptionButtons(
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
                          await windowManager.minimize();
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
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class WindowCaptionButtons extends StatelessWidget {
  final List<Widget> children;
  const WindowCaptionButtons({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
