import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../../domain/operations/task_operations.dart';
import 'task_kind_label.dart';

/// Dialog tambah/edit tugas dengan validasi nama, target, dan status aktif.
class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({
    super.key,
    this.task,
    required this.onValidateName,
    required this.onSave,
    this.failureMessage,
  });

  /// `null` berarti mode tambah.
  final Task? task;
  final String? Function(String name) onValidateName;
  final String? Function()? failureMessage;
  final Future<bool> Function({
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
  })
  onSave;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetDailyController;
  late final TextEditingController _targetTotalController;
  late TaskKind _kind;
  late bool _isActive;
  bool _submitting = false;
  String? _submitError;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _kind = task?.kind ?? TaskKind.habit;
    _isActive = task?.isActive ?? true;
    _nameController = TextEditingController(text: task?.name ?? '');
    _targetDailyController = TextEditingController(
      text: '${task?.targetDaily ?? 0}',
    );
    _targetTotalController = TextEditingController(
      text: (task?.targetTotal ?? 0) > 0 ? '${task!.targetTotal}' : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetDailyController.dispose();
    _targetTotalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTotal = _kind == TaskKind.progress;

    return AlertDialog(
      title: Text(_isEditing ? 'Ubah Tugas' : 'Tambah Tugas Baru'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('taskNameField'),
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Tugas',
                  hintText: 'Contoh: Push up',
                ),
                maxLength: maxTaskNameLength,
                validator: (value) => widget.onValidateName(value ?? ''),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskKind>(
                key: const Key('taskKindField'),
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Jenis Tugas'),
                items: [
                  for (final kind in TaskKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text(taskKindLabel(kind)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _kind = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('taskTargetDailyField'),
                controller: _targetDailyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Harian',
                  helperText: 'Isi 0 bila tidak ada target harian',
                ),
                validator: _validateDaily,
              ),
              if (showTotal) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('taskTargetTotalField'),
                  controller: _targetTotalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Total',
                    helperText: 'Wajib lebih dari 0 untuk tugas Progres',
                  ),
                  validator: _validateTotal,
                ),
              ],
              const SizedBox(height: 4),
              SwitchListTile(
                key: const Key('taskActiveSwitch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Tugas aktif'),
                subtitle: Text(
                  _isActive
                      ? 'Tugas dihitung dalam ringkasan harian'
                      : 'Riwayat tetap tersimpan, tugas tidak dihitung',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _submitError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('taskCancelButton'),
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('taskSaveButton'),
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  String? _validateDaily(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return 'Masukkan angka bulat';
    return validateTaskDailyTarget(parsed);
  }

  String? _validateTotal(String? value) {
    if (_kind != TaskKind.progress) return null;
    final trimmed = value?.trim() ?? '';
    final parsed = trimmed.isEmpty ? 0 : int.tryParse(trimmed);
    if (parsed == null) return 'Masukkan angka bulat';
    return validateTaskTotalTarget(kind: _kind, targetTotal: parsed);
  }

  int get _parsedDaily {
    final trimmed = _targetDailyController.text.trim();
    if (trimmed.isEmpty) return 0;
    return int.tryParse(trimmed) ?? 0;
  }

  int get _parsedTotal {
    final trimmed = _targetTotalController.text.trim();
    if (trimmed.isEmpty) return 0;
    return int.tryParse(trimmed) ?? 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final saved = await widget.onSave(
      name: _nameController.text.trim(),
      kind: _kind,
      targetDaily: _parsedDaily,
      targetTotal: _parsedTotal,
      isActive: _isActive,
    );

    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _submitError =
            widget.failureMessage?.call() ??
            'Perubahan belum tersimpan. Silakan coba lagi.';
      });
    }
  }
}
