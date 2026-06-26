// lib/features/documents/presentation/screens/my_documents_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: Colors.indigo[700],
      ),
      drawer: const DrawerMenu(
        isDocumentsActive: true,
      ), // Aktifkan sekat menu pembatas halaman dokumen
      body: const Center(
        child: Text(
          'Halaman dokumen masih kosong.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
