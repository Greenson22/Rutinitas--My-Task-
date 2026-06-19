// lib/features/random/presentation/screens/random_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';

enum RandomType { angka, huruf }

class RandomScreen extends StatefulWidget {
  const RandomScreen({super.key});

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen> {
  RandomType _selectedType = RandomType.angka;

  // Controller untuk Angka
  final TextEditingController _minController = TextEditingController(text: '0');
  final TextEditingController _maxController = TextEditingController(
    text: '10',
  );

  // Controller untuk Huruf
  final TextEditingController _minLetterController = TextEditingController(
    text: 'A',
  );
  final TextEditingController _maxLetterController = TextEditingController(
    text: 'E',
  );

  String? _result;
  final Random _random = Random();

  void _generateRandomValue() {
    setState(() {
      if (_selectedType == RandomType.angka) {
        // Logika Acak Angka
        int min = int.tryParse(_minController.text) ?? 0;
        int max = int.tryParse(_maxController.text) ?? 10;

        if (min > max) {
          final temp = min;
          min = max;
          max = temp;
          _minController.text = min.toString();
          _maxController.text = max.toString();
        }

        _result = (min + _random.nextInt((max - min) + 1)).toString();
      } else {
        // Logika Acak Huruf
        String minStr = _minLetterController.text.trim().toUpperCase();
        String maxStr = _maxLetterController.text.trim().toUpperCase();

        // Validasi jika input kosong, beri default A-E
        if (minStr.isEmpty) minStr = 'A';
        if (maxStr.isEmpty) maxStr = 'E';

        // Ambil kode ASCII dari huruf pertama
        int minCode = minStr.codeUnitAt(0);
        int maxCode = maxStr.codeUnitAt(0);

        // Pastikan input adalah huruf alfabet valid (A-Z)
        if (minCode < 65 || minCode > 90) minCode = 65; // 'A'
        if (maxCode < 65 || maxCode > 90) maxCode = 69; // 'E'

        if (minCode > maxCode) {
          final temp = minCode;
          minCode = maxCode;
          maxCode = temp;
          _minLetterController.text = String.fromCharCode(minCode);
          _maxLetterController.text = String.fromCharCode(maxCode);
        }

        int randomCode = minCode + _random.nextInt((maxCode - minCode) + 1);
        _result = String.fromCharCode(randomCode);
      }
    });
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minLetterController.dispose();
    _maxLetterController.dispose();
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
                // Pilihan Mode: Angka atau Huruf
                SegmentedButton<RandomType>(
                  segments: const <ButtonSegment<RandomType>>[
                    ButtonSegment<RandomType>(
                      value: RandomType.angka,
                      label: Text('Angka'),
                      icon: Icon(Icons.numbers),
                    ),
                    ButtonSegment<RandomType>(
                      value: RandomType.huruf,
                      label: Text('Huruf'),
                      icon: Icon(Icons.text_fields),
                    ),
                  ],
                  selected: <RandomType>{_selectedType},
                  onSelectionChanged: (Set<RandomType> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                      _result = null; // Reset hasil saat ganti mode
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Card Display Utama untuk Hasil
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
                          _selectedType == RandomType.angka
                              ? 'ANGKA ACAK'
                              : 'HURUF ACAK',
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
                            _result ?? '?',
                            key: ValueKey<String>(_result ?? '-'),
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

                // Card Input Rentang (Kondisional berdasarkan pilihan mode)
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedType == RandomType.angka
                              ? 'Tentukan Rentang Angka'
                              : 'Tentukan Rentang Huruf (A-Z)',
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
                                controller: _selectedType == RandomType.angka
                                    ? _minController
                                    : _minLetterController,
                                keyboardType: _selectedType == RandomType.angka
                                    ? TextInputType.number
                                    : TextInputType.text,
                                maxLength: _selectedType == RandomType.huruf
                                    ? 1
                                    : null,
                                decoration: InputDecoration(
                                  counterText:
                                      "", // Menyembunyikan counter panjang teks
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
                                controller: _selectedType == RandomType.angka
                                    ? _maxController
                                    : _maxLetterController,
                                keyboardType: _selectedType == RandomType.angka
                                    ? TextInputType.number
                                    : TextInputType.text,
                                maxLength: _selectedType == RandomType.huruf
                                    ? 1
                                    : null,
                                decoration: InputDecoration(
                                  counterText: "",
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

                // Tombol Generator
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _generateRandomValue,
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
