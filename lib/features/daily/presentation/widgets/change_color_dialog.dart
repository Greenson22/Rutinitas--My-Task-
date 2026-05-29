// lib/features/daily/presentation/widgets/change_color_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';

class ChangeColorDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onColorSaved;

  const ChangeColorDialog({
    super.key,
    required this.subject,
    required this.onColorSaved,
  });

  @override
  State<ChangeColorDialog> createState() => _ChangeColorDialogState();
}

class _ChangeColorDialogState extends State<ChangeColorDialog> {
  late Color _selectedBgColor;
  late Color _selectedTextColor;

  final _hexInputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isTextDarkForCustom = true;

  // Daftar warna kustom tambahan (Menggunakan objek Color untuk UI Picker)
  // Daftar warna kustom tambahan di dalam _ChangeColorDialogState
  final List<Map<String, Color>> _extendedPalette = [
    {'bg': const Color(0xFFFADBD8), 'text': const Color(0xFF78281F)},
    {'bg': const Color(0xFFD4EFDF), 'text': const Color(0xFF145A32)},
    {'bg': const Color(0xFFD6EAF8), 'text': const Color(0xFF1B4F72)},
    {'bg': const Color(0xFFFCF3CF), 'text': const Color(0xFF7E5109)},
    {'bg': const Color(0xFFE8DAEF), 'text': const Color(0xFF4A235A)},
    {'bg': const Color(0xFFE5E8E8), 'text': const Color(0xFF1C2833)},
    {'bg': const Color(0xFFEDBB99), 'text': const Color(0xFF6E2C00)},
    {'bg': const Color(0xFFA2D9CE), 'text': const Color(0xFF0E6251)},
    {'bg': const Color(0xFFF5CBA7), 'text': const Color(0xFF784212)},
    {'bg': const Color(0xFFD7BDE2), 'text': const Color(0xFF4A235A)},
    // Ekstra tambahan warna agar GridView meluas di UI
    {'bg': const Color(0xFFE8F8F5), 'text': const Color(0xFF117A65)},
    {'bg': const Color(0xFFEBDEF0), 'text': const Color(0xFF6C3483)},
    {'bg': const Color(0xFFEBF5FB), 'text': const Color(0xFF2E86C1)},
    {'bg': const Color(0xFFFDF2E9), 'text': const Color(0xFFA04000)},
    {'bg': const Color(0xFFFCE4EC), 'text': const Color(0xFFC2185B)},
  ];
  @override
  void initState() {
    super.initState();
    // Mengonversi int dari model menjadi objek Color untuk kebutuhan UI Dialog
    _selectedBgColor = Color(widget.subject.backgroundColor);
    _selectedTextColor = Color(widget.subject.textColor);
    _updateHexTextField(_selectedBgColor);
  }

  @override
  void dispose() {
    _hexInputController.dispose();
    super.dispose();
  }

  void _updateHexTextField(Color color) {
    _hexInputController.text = color.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  void _applyCustomHexColor(String val) {
    String cleanHex = val.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    final int? parsedValue = int.tryParse(cleanHex, radix: 16);
    if (parsedValue != null) {
      final Color newBgColor = Color(parsedValue);
      final Brightness brightness = ThemeData.estimateBrightnessForColor(
        newBgColor,
      );

      setState(() {
        _selectedBgColor = newBgColor;
        // Mengabaikan dropdown manual dan mendeteksi otomatis kecerahan kode HEX
        _selectedTextColor = (brightness == Brightness.dark)
            ? Colors.white
            : Colors.black87;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.palette_outlined, color: Colors.teal),
          SizedBox(width: 8),
          Text('Ubah Warna Materi'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LIVE PREVIEW
                const Text(
                  'Pratinjau Tampilan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.subject.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subject.namaMateri,
                        style: TextStyle(
                          color: _selectedTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. INPUT KODE HEX
                const Text(
                  'Warna Bebas / Kustom (Kode HEX):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hexInputController,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: 'F5CBA7',
                          prefixText: '# ',
                          isDense: true,
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return null;
                          if (value.trim().length != 6)
                            return 'Harus 6 karakter';
                          if (int.tryParse(value.trim(), radix: 16) == null) {
                            return 'HEX tidak valid';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          if (val.trim().length == 6) {
                            _applyCustomHexColor(val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const Text(
                          'Warna Teks',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        DropdownButton<bool>(
                          value: _isTextDarkForCustom,
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Gelap')),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Putih'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _isTextDarkForCustom = val;
                                _selectedTextColor = val
                                    ? Colors.black87
                                    : Colors.white;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. PALET TAMBAHAN
                const Text(
                  'Pilihan Palet Warna Tambahan:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _extendedPalette.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, idx) {
                    final colorPair = _extendedPalette[idx];
                    final Color bg = colorPair['bg']!;
                    final Color text = colorPair['text']!;
                    final bool isSelected = _selectedBgColor.value == bg.value;

                    return InkWell(
                      onTap: () {
                        final Brightness brightness =
                            ThemeData.estimateBrightnessForColor(bg);
                        setState(() {
                          _selectedBgColor = bg;
                          // Mengabaikan warna teks bawaan palet dan menghitung kecerahan murninya
                          _selectedTextColor = (brightness == Brightness.dark)
                              ? Colors.white
                              : Colors.black87;
                          _updateHexTextField(bg);
                        });
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal.shade700
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: text, size: 18)
                            : const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ), // Penutup content yang benar agar selevel dengan actions
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // 1. Tentukan tingkat kecerahan dari warna latar belakang yang dipilih
              final Brightness brightness =
                  ThemeData.estimateBrightnessForColor(_selectedBgColor);

              // 2. Jika warna latar belakang cenderung GELAP, ubah teks menjadi PUTIH.
              //    Jika warna latar belakang cenderung TERANG, ubah teks menjadi HITAM/GELAP.
              final Color adaptiveTextColor = (brightness == Brightness.dark)
                  ? Colors.white
                  : Colors.black87;

              // 3. Simpan nilai integer (.value) ke model data
              widget.subject.backgroundColor = _selectedBgColor.value;
              widget.subject.textColor = adaptiveTextColor.value;

              widget.onColorSaved();
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
          child: const Text(
            'Simpan Warna',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
