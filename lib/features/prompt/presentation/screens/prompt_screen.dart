// lib/features/prompt/presentation/screens/prompt_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';

class PromptScreen extends StatelessWidget {
  const PromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt'),
        backgroundColor: Colors.indigo,
      ),
      // Menampilkan drawer_menu agar pengguna bisa kembali ke halaman lain
      drawer: const DrawerMenu(isPromptActive: true),
      body: const Center(
        child: Text(
          'Halaman Prompt (Masih Kosong)',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
