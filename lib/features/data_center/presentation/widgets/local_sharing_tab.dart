import 'dart:io';

import 'package:flutter/material.dart';

class LocalSharingTab extends StatelessWidget {
  final VoidCallback onSendFile;
  final VoidCallback onReceiveFile;
  final List<File> serverBackupFiles;
  final Function(File) onDeleteServerBackup;

  const LocalSharingTab({
    super.key,
    required this.onSendFile,
    required this.onReceiveFile,
    required this.serverBackupFiles,
    required this.onDeleteServerBackup,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kirim & Terima Data Lokal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                // Pilihan Operasi 1: Mode Server / Pengirim
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.cloud_upload)),
                  title: const Text('Mode Pengirim (Server)'),
                  trailing: ElevatedButton(
                    onPressed: onSendFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text('Kirim File'),
                  ),
                ),

                const Divider(),

                // Pilihan Operasi 2: Mode Client / Penerima
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.cloud_download),
                  ),
                  title: const Text('Mode Penerima (Client)'),
                  trailing: ElevatedButton(
                    onPressed: onReceiveFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text('Terima File'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(thickness: 2),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Daftar Berkas Backup (Dari Server)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        // Menampilkan daftar berkas server
        serverBackupFiles.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada file backup dari server.'),
                ),
              )
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
                      onPressed: () => onDeleteServerBackup(file),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
