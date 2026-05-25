import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'package:intl/intl.dart'; // Digunakan untuk memformat objek DateTime ke string YYYY-MM-DD

class EditTaskDialog extends StatefulWidget {
  final TaskItem task;
  final Function({
    required String newName,
    required int newCount,
    required int newCountToday,
    required int newTargetCount,
    required int newTargetCountToday,
    required String? newDate,
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

  // === FUNGSI UTK MEMBUKA DATE PICKER YANG MUDAH ===
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    // Jika data date sebelumnya valid, gunakan sebagai initial date picker
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
        // Format otomatis ke format YYYY-MM-DD
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
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Tugas'),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _countController,
                decoration: const InputDecoration(labelText: 'Total Count'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _countTodayController,
                decoration: const InputDecoration(labelText: 'Count Hari Ini'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _targetCountController,
                decoration: const InputDecoration(labelText: 'Target Total'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _targetCountTodayController,
                decoration: const InputDecoration(labelText: 'Target Hari Ini'),
                keyboardType: TextInputType.number,
              ),
              // === INPUT DATE YANG DIUBAH MENJADI DATE PICKER KALENDER ===
              TextFormField(
                controller: _dateController,
                readOnly: true, // Menghindari keyboard muncul saat ditekan
                decoration: InputDecoration(
                  labelText: 'Tanggal (YYYY-MM-DD)',
                  hintText: 'Pilih Tanggal',
                  suffixIcon: _dateController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _dateController.clear()),
                        )
                      : const Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
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
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
