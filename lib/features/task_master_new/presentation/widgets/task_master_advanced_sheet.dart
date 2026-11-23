import 'package:flutter/material.dart';

/// Area Advanced Task Master New.
///
/// Pilihan berisiko seperti editor JSON mentah sengaja tidak diletakkan di
/// menu utama. Pengaturan folder dan enkripsi berasal dari core sehingga modul
/// baru tidak bergantung pada modul Task Master lama.
class TaskMasterAdvancedSheet extends StatelessWidget {
  const TaskMasterAdvancedSheet({
    super.key,
    required this.onOpenRawJsonEditor,
  });

  final VoidCallback onOpenRawJsonEditor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        key: const Key('taskMasterAdvancedSheet'),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Advanced',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              key: const Key('openRawJsonEditorTile'),
              leading: const Icon(Icons.code_rounded, color: Colors.indigo),
              title: const Text('Editor JSON mentah'),
              subtitle: const Text(
                'Validasi JSON sebelum menyimpan. Atomic write dan enkripsi '
                'tetap aktif.',
              ),
              onTap: onOpenRawJsonEditor,
            ),
          ],
        ),
      ),
    );
  }
}
