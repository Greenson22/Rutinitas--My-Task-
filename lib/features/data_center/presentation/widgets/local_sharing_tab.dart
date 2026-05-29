// lib/features/data_center/presentation/widgets/local_sharing_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';

class LocalSharingTab extends StatefulWidget {
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
  State<LocalSharingTab> createState() => _LocalSharingTabState();
}

class _LocalSharingTabState extends State<LocalSharingTab> {
  // Deklarasi variabel state untuk manajemen hapus masal berkas server
  bool _isServerSelectionMode = false;
  final List<File> _selectedServerFiles = [];

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
                    onPressed: widget
                        .onSendFile, // Menggunakan widget. untuk mengakses parameter parent
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
                    onPressed: widget
                        .onReceiveFile, // Menggunakan widget. untuk mengakses parameter parent
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

        // === TOMBOL KONTROL MASAL ===
        if (_isServerSelectionMode) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .end, // Menggeser deretan kontrol ke kanan layar
              children: [
                // Info jumlah file yang sedang dicentang
                Text(
                  '${_selectedServerFiles.length} Terpilih  ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                // Tombol utama eksekusi hapus masal
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(
                    Icons.delete_sweep,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Hapus Masal',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _selectedServerFiles.isEmpty
                      ? null // Tombol tidak bisa diklik jika belum ada yang dicentang
                      : () async {
                          // Melakukan perulangan untuk menghapus setiap file yang dicentang dari penyimpanan lokal
                          for (var file in _selectedServerFiles) {
                            if (await file.exists()) {
                              await file.delete();
                            }
                          }
                          // Reset state kembali ke mode normal setelah selesai menghapus
                          setState(() {
                            _selectedServerFiles.clear();
                            _isServerSelectionMode = false;
                          });
                          // Memicu refresh data pada layar utama (DataCenterScreen) dengan mengirimkan objek file kosong
                          widget.onDeleteServerBackup(File(''));
                        },
                ),
                const SizedBox(width: 8),

                // Tombol untuk membatalkan pilihan masal
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedServerFiles.clear();
                      _isServerSelectionMode =
                          false; // Kembali ke mode tampilan biasa
                    });
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Menampilkan daftar berkas dari server
        widget
                .serverBackupFiles
                .isEmpty // Menggunakan widget. untuk mengakses list file
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada file backup dari server.'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    widget.serverBackupFiles.length, // Menggunakan widget.
                itemBuilder: (context, index) {
                  final file =
                      widget.serverBackupFiles[index]; // Menggunakan widget.
                  final isSelected = _selectedServerFiles.contains(file);

                  return ListTile(
                    // Jika ditahan lama, aktifkan mode pemilihan massal dan otomatis centang file ini
                    onLongPress: () {
                      setState(() {
                        _isServerSelectionMode = true;
                        if (!isSelected) _selectedServerFiles.add(file);
                      });
                    },
                    // Jika diklik biasa dalam mode pemilihan, lakukan toggle centang (tambah/hapus dari list)
                    onTap: _isServerSelectionMode
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedServerFiles.remove(file);
                              } else {
                                _selectedServerFiles.add(file);
                              }
                            });
                          }
                        : null,
                    // Ikon kiri berubah menjadi Checkbox apabila mode pemilihan masal sedang aktif
                    leading: _isServerSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            activeColor: Colors.red,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedServerFiles.add(file);
                                } else {
                                  _selectedServerFiles.remove(file);
                                }
                              });
                            },
                          )
                        : const Icon(Icons.cloud_download, color: Colors.teal),
                    title: Text(file.path.split('/').last),
                    // Sembunyikan tombol hapus satuan sampah saat sedang memilih banyak file
                    trailing: _isServerSelectionMode
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => widget.onDeleteServerBackup(
                              file,
                            ), // Menggunakan widget.
                          ),
                  );
                },
              ),
      ],
    );
  }
}
