// lib/main.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 1. Tambahkan import AdMob
import 'features/task_master/presentation/screens/task_master_screen.dart';
import 'features/task_master/presentation/widgets/password_gate.dart';

void main() async {
  // 2. Ubah fungsi main menjadi async
  // 3. Pastikan binding Flutter telah diinisialisasi sebelum mengakses native SDK
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inisialisasi SDK AdMob
  await MobileAds.instance.initialize();

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

      // Menggunakan properti builder untuk membungkus seluruh hierarki navigasi
      builder: (context, child) {
        // Pastikan child tidak null (child di sini adalah Navigator bawaan MaterialApp)
        Widget appNavigator = child!;

        // PERBAIKAN: Langsung teruskan appNavigator ke PasswordGate.
        // Jangan dibungkus dengan Navigator lokal di sini agar tombol Back Android
        // dapat menutup dialog di dalam aplikasi dengan normal.
        Widget secureApp = PasswordGate(child: appNavigator); //[cite: 3]

        // Evaluasi platform untuk Window Control (Desktop)
        final platform = Theme.of(context).platform; //[cite: 3]
        if (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux) {
          //[cite: 3]
          return WindowControlWrapper(child: secureApp); //[cite: 3]
        }

        return secureApp; //[cite: 3]
      },
      home: const HomeScreen(),
    );
  }
}

class WindowControlWrapper extends StatelessWidget {
  //[cite: 3]
  final Widget child;
  const WindowControlWrapper({super.key, required this.child}); //[cite: 3]

  @override
  Widget build(BuildContext context) {
    //[cite: 3]
    return Scaffold(
      //[cite: 3]
      body: Column(
        //[cite: 3]
        children: [
          Container(
            //[cite: 3]
            color: Colors.indigo.shade700, //[cite: 3]
            height: 30, //[cite: 3]
            child: Row(
              //[cite: 3]
              children: [
                const SizedBox(width: 10), //[cite: 3]
                const Text(
                  //[cite: 3]
                  'My Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(), //[cite: 3]
                WindowCaptionButtons(
                  //[cite: 3]
                  children: [
                    SizedBox(
                      //[cite: 3]
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
                          await windowManager.minimize(); //[cite: 3]
                        },
                      ),
                    ),
                    SizedBox(
                      //[cite: 3]
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
                            //[cite: 3]
                            await windowManager.unmaximize(); //[cite: 3]
                          } else {
                            await windowManager.maximize(); //[cite: 3]
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      //[cite: 3]
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
                          await windowManager.close(); //[cite: 3]
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: child), //[cite: 3]
        ],
      ),
    );
  }
}

class WindowCaptionButtons extends StatelessWidget {
  //[cite: 3]
  final List<Widget> children;
  const WindowCaptionButtons({super.key, required this.children}); //[cite: 3]

  @override
  Widget build(BuildContext context) {
    //[cite: 3]
    return Row(mainAxisSize: MainAxisSize.min, children: children); //[cite: 3]
  }
}
