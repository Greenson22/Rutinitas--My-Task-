// lib/features/task_master/presentation/widgets/edit_task_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class EditTaskDialog extends StatefulWidget {
  final TaskItem task;
  final Function({
    required String newName,
    required int newCount,
    required int newCountToday,
    required int newTargetCount,
    required int newTargetCountToday,
    required String? newDate,
    required bool newIsActive,
    required int newType, // <--- TAMBAHAN PARAMETER BARU
  })
  onSave;

  const EditTaskDialog({super.key, required this.task, required this.onSave});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _countController;
  late TextEditingController _countTodayController;
  late TextEditingController _targetCountController;
  late TextEditingController _targetCountTodayController;
  late TextEditingController _dateController;
  late bool _isActive;
  late int _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _countController = TextEditingController(
      text: widget.task.count.toString(),
    );
    _countTodayController = TextEditingController(
      text: widget.task.countToday.toString(),
    );
    _targetCountController = TextEditingController(
      text: widget.task.targetCount.toString(),
    );
    _targetCountTodayController = TextEditingController(
      text: widget.task.targetCountToday.toString(),
    );
    _dateController = TextEditingController(text: widget.task.date ?? '');
    _isActive = widget.task.isActive;
    _selectedType = widget.task.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _countTodayController.dispose();
    _targetCountController.dispose();
    _targetCountTodayController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_dateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dateController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Detail Tugas'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Tugas',
                  icon: Icon(Icons.task_alt),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),

              // DROPDOWN DENGAN IKON YANG VALID
              DropdownButtonFormField<int>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Tugas',
                  icon: Icon(
                    Icons.stacked_line_chart,
                  ), // <--- PERBAIKAN TYPO HURUF ASING
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Tugas Biasa')),
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Tugas Progress (Ada Progress Bar)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Hitungan & Statistik Progress:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontSize: 13,
                  ),
                ),
              ),

              TextFormField(
                controller: _countController,
                decoration: const InputDecoration(
                  labelText: 'Total Count Saat Ini',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _countTodayController,
                decoration: const InputDecoration(labelText: 'Count Hari Ini'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _targetCountController,
                decoration: InputDecoration(
                  labelText: 'Target Total Progress',
                  hintText: 'Contoh: 1000',
                  labelStyle: TextStyle(
                    color: _selectedType == 1
                        ? Colors.indigo[700]
                        : Colors.black54,
                    fontWeight: _selectedType == 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _targetCountTodayController,
                decoration: const InputDecoration(labelText: 'Target Hari Ini'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              const Divider(),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal Terakhir Update (YYYY-MM-DD)',
                  hintText: 'Pilih Tanggal',
                  icon: const Icon(Icons.calendar_today, size: 20),
                  suffixIcon: _dateController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _dateController.clear()),
                        )
                      : null,
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text('Status Tugas Aktif'),
                subtitle: const Text(
                  'Jika mati, tidak dihitung di ringkasan',
                  style: TextStyle(fontSize: 11),
                ),
                value: _isActive,
                activeColor: Colors.indigo,
                contentPadding: EdgeInsets.zero,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Kirim seluruh perubahan data melalui callback terstruktur
              widget.onSave(
                newName: _nameController.text.trim(),
                newCount:
                    int.tryParse(_countController.text) ?? widget.task.count,
                newCountToday:
                    int.tryParse(_countTodayController.text) ??
                    widget.task.countToday,
                newTargetCount:
                    int.tryParse(_targetCountController.text) ??
                    widget.task.targetCount,
                newTargetCountToday:
                    int.tryParse(_targetCountTodayController.text) ??
                    widget.task.targetCountToday,
                newDate: _dateController.text.trim().isEmpty
                    ? null
                    : _dateController.text.trim(),
                newIsActive: _isActive,
                newType: _selectedType, // <--- SALURKAN NILAI BARU KE SINI
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
