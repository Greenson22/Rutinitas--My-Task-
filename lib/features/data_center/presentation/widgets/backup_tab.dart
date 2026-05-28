import 'dart:io';
import 'package:flutter/material.dart';

class BackupTab extends StatelessWidget {
  final List<File> localBackupFiles;
  final VoidCallback onCreateBackup;
  final Function(File) onDeleteBackup;
  final VoidCallback onBackupTaskMaster;
  final VoidCallback onRestoreTaskMaster;
  final VoidCallback onBackupChecklist;
  final VoidCallback onRestoreChecklist;
  final VoidCallback onBackupJurnal;
  final VoidCallback onRestoreJurnal;

  const BackupTab({
    super.key,
    required this.localBackupFiles,
    required this.onCreateBackup,
    required this.onDeleteBackup,
    required this.onBackupTaskMaster,
    required this.onRestoreTaskMaster,
    required this.onBackupChecklist,
    required this.onRestoreChecklist,
    required this.onBackupJurnal,
    required this.onRestoreJurnal,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Baris Tombol Ringkas (Task Master, Checklist, Jurnal)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactButton(
                'Task Master',
                Icons.format_list_bulleted,
                onBackupTaskMaster,
                onRestoreTaskMaster,
              ),
              _buildCompactButton(
                'Checklist',
                Icons.checklist_rtl,
                onBackupChecklist,
                onRestoreChecklist,
              ),
              _buildCompactButton(
                'Jurnal',
                Icons.menu_book,
                onBackupJurnal,
                onRestoreJurnal,
              ),
            ],
          ),
        ),

        const Divider(thickness: 2),

        // Bagian Header Daftar Berkas & Tombol Buat ZIP
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Berkas Backup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: onCreateBackup,
                icon: const Icon(Icons.add),
                label: const Text('Buat Backup (.zip)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
        ),

        // Daftar File ZIP Lokal
        localBackupFiles.isEmpty
            ? const Center(child: Text('Belum ada file backup.'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: localBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = localBackupFiles[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_zip, color: Colors.amber),
                    title: Text(file.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => onDeleteBackup(file),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // Helper Widget untuk tombol internal di dalam Tab Backup
  Widget _buildCompactButton(
    String label,
    IconData icon,
    VoidCallback onUp,
    VoidCallback onDown,
  ) {
    return Column(
      children: [
        CircleAvatar(child: Icon(icon, color: Colors.indigo)),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
              onPressed: onUp,
            ),
            IconButton(
              icon: const Icon(
                Icons.cloud_download_outlined,
                color: Colors.green,
              ),
              onPressed: onDown,
            ),
          ],
        ),
      ],
    );
  }
}
