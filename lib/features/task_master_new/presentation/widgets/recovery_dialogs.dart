import 'package:flutter/material.dart';

import '../../domain/entities/task_backup.dart';

/// Dialog PIN untuk membuka file Task Master yang gagal didekripsi.
class TaskMasterPinDialog extends StatefulWidget {
  const TaskMasterPinDialog({super.key, required this.onUnlock});

  /// Mengembalikan `true` bila PIN berhasil membuka data.
  final Future<bool> Function(String pin) onUnlock;

  @override
  State<TaskMasterPinDialog> createState() => _TaskMasterPinDialogState();
}

class _TaskMasterPinDialogState extends State<TaskMasterPinDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'PIN wajib diisi.');
      return;
    }
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final unlocked = await widget.onUnlock(pin);
    if (!mounted) return;
    if (unlocked) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = 'PIN tidak cocok. Periksa kembali atau pulihkan backup.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Colors.indigo),
          SizedBox(width: 8),
          Expanded(child: Text('Buka dengan PIN')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'File Task Master terenkripsi. Masukkan PIN/kata sandi yang '
            'dipakai saat enkripsi diaktifkan.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('pinField'),
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            enabled: !_submitting,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'PIN / Kata sandi',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Tampilkan PIN' : 'Sembunyikan PIN',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const Key('pinError'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('pinConfirmButton'),
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Buka'),
        ),
      ],
    );
  }
}

/// Daftar backup yang dapat dipulihkan.
class TaskMasterBackupDialog extends StatelessWidget {
  const TaskMasterBackupDialog({super.key, required this.backups});

  final List<TaskBackup> backups;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pulihkan backup'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih backup yang ingin dipulihkan. File saat ini akan '
              'diganti oleh isi backup.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: backups.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  return ListTile(
                    key: Key('restoreBackup_$index'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.settings_backup_restore_rounded,
                      color: Colors.teal,
                    ),
                    title: Text(
                      formatTaskBackupTimestamp(backup.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Backup ${index + 1} dari ${backups.length}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(backup),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

/// Konfirmasi destruktif sebelum memulihkan backup.
class TaskMasterRestoreConfirmDialog extends StatelessWidget {
  const TaskMasterRestoreConfirmDialog({super.key, required this.backup});

  final TaskBackup backup;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pulihkan backup ini?'),
      content: Text(
        'Data Task Master saat ini akan diganti dengan backup '
        '${formatTaskBackupTimestamp(backup.createdAt)}. '
        'Tindakan ini tidak dapat dibatalkan dari dalam aplikasi.',
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('confirmRestoreBackupButton'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('Pulihkan'),
        ),
      ],
    );
  }
}

/// Konfirmasi destruktif sebelum membuat file baru.
class TaskMasterCreateNewFileDialog extends StatelessWidget {
  const TaskMasterCreateNewFileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          SizedBox(width: 8),
          Expanded(child: Text('Buat file baru?')),
        ],
      ),
      content: const Text(
        'File Task Master saat ini akan dibackup terlebih dahulu, lalu '
        'diganti dengan file kosong. Semua kategori dan tugas akan hilang '
        'dari tampilan sampai backup dipulihkan. Lanjutkan?',
        style: TextStyle(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('confirmCreateNewFileButton'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Buat file baru'),
        ),
      ],
    );
  }
}

/// Format waktu backup tanpa bergantung pada locale perangkat.
String formatTaskBackupTimestamp(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.day)}/${two(time.month)}/${time.year} '
      '${two(time.hour)}:${two(time.minute)}';
}
