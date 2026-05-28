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
  final VoidCallback onRestoreAllZip;
  final List<File> serverBackupFiles; // <-- Tambah ini
  final Function(File) onDeleteServerBackup; // <-- Tambah ini

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
    required this.onRestoreAllZip,
    required this.serverBackupFiles,
    required this.onDeleteServerBackup,
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
              FittedBox(
                child: Row(
                  children: [
                    // Memperpendek teks agar muat di layar HP
                    ElevatedButton.icon(
                      onPressed: onRestoreAllZip,
                      icon: const Icon(Icons.unarchive, size: 16),
                      label: const Text(
                        'Import',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: onCreateBackup,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Backup',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
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

        // TAMBAHKAN kode UI ini di dalam ListView bagian paling bawah (di bawah localBackupFiles)
        const Divider(thickness: 2),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: const Text(
            'Daftar Berkas Backup (Dari Server)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        serverBackupFiles.isEmpty
            ? const Center(child: Text('Belum ada file backup dari server.'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: serverBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = serverBackupFiles[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.cloud_download,
                      color: Colors.teal,
                    ),
                    title: Text(file.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        // Tampilkan Dialog Konfirmasi Hapus
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Backup Server?'),
                            content: const Text(
                              'Apakah Anda yakin ingin menghapus berkas backup dari server ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );

                        // Jika setuju hapus, jalankan fungsi penghapusan
                        if (confirm == true) {
                          onDeleteServerBackup(file);
                        }
                      },
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
        CircleAvatar(child: Icon(icon, color: Colors.white)),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        // SESUDAH DIUBAH (Berikan pembatas jarak dan perkecil ukuran tombol):
        Row(
          mainAxisSize:
              MainAxisSize.min, // Agar baris tidak memakan tempat terlalu lebar
          children: [
            IconButton(
              padding:
                  EdgeInsets.zero, // Menghilangkan ruang kosong bawaan tombol
              constraints: const BoxConstraints(), // Membantu merapatkan tombol
              icon: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.blue,
                size: 20,
              ), // Ditambahkan ukuran (size) 20
              onPressed: onUp,
            ),
            const SizedBox(
              width: 8,
            ), // Memberikan jarak horizontal agar tidak menempel
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.cloud_download_outlined,
                color: Colors.green,
                size: 20,
              ), // Ditambahkan ukuran (size) 20
              onPressed: onDown,
            ),
          ],
        ),
      ],
    );
  }
}
