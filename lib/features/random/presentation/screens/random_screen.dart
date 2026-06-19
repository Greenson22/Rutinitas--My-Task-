// lib/features/random/presentation/screens/random_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';

class RandomScreen extends StatefulWidget {
  const RandomScreen({super.key});

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen> {
  final TextEditingController _minController = TextEditingController(text: '0');
  final TextEditingController _maxController = TextEditingController(
    text: '10',
  );
  int? _result;
  final Random _random = Random();

  void _generateRandomNumber() {
    int min = int.tryParse(_minController.text) ?? 0;
    int max = int.tryParse(_maxController.text) ?? 10;

    if (min > max) {
      // Tukar posisi jika min lebih besar dari max secara tidak sengaja
      final temp = min;
      min = max;
      max = temp;
      _minController.text = min.toString();
      _maxController.text = max.toString();
    }

    setState(() {
      _result = min + _random.nextInt((max - min) + 1);
    });
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Generator'),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
      ),
      drawer: const DrawerMenu(isRandomActive: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card Display Utama untuk Hasil Angka
                Card(
                  elevation: 8,
                  shadowColor: Colors.indigo.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ANGKA ACAK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[300],
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                          child: Text(
                            _result != null ? '$_result' : '?',
                            key: ValueKey<int>(_result ?? -1),
                            style: TextStyle(
                              fontSize: 84,
                              fontWeight: FontWeight.w900,
                              color: Colors.indigo[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Card Input Pengaturan Rentang Angka
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // DIUBAH: Typo 'cross CrossAxisAlignment' diperbaiki ke nama parameter yang benar
                      children: [
                        Text(
                          'Tentukan Rentang Angka',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Min',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.arrow_downward),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.arrow_upward),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Tombol Generator (DIUBAH dari SizedBox ke Container untuk menghindari error constraints)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _generateRandomNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.casino, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'ACAK SEKARANG',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
