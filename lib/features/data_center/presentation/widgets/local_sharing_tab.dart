// lib/features/data_center/presentation/widgets/local_sharing_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';

class LocalSharingTab extends StatefulWidget {
  final VoidCallback onSendFile;
  final VoidCallback onReceiveFile;
  final List<File> serverBackupFiles;
  final Function(File) onDeleteServerBackup;
  final Function(File) onRestoreAllZip;

  const LocalSharingTab({
    super.key,
    required this.onSendFile,
    required this.onReceiveFile,
    required this.serverBackupFiles,
    required this.onDeleteServerBackup,
    required this.onRestoreAllZip,
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    _selectedServerFiles.length ==
                            widget.serverBackupFiles.length
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 18,
                    color: Colors.teal[700],
                  ),
                  tooltip:
                      _selectedServerFiles.length ==
                          widget.serverBackupFiles.length
                      ? 'Batal Semua'
                      : 'Pilih Semua',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  onPressed: () {
                    setState(() {
                      if (_selectedServerFiles.length ==
                          widget.serverBackupFiles.length) {
                        _selectedServerFiles.clear();
                      } else {
                        _selectedServerFiles.clear();
                        _selectedServerFiles.addAll(widget.serverBackupFiles);
                      }
                    });
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  '${_selectedServerFiles.length} Terpilih',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),

                // === PERBAIKAN DI SINI: MENAMBAHKAN DIALOG KONFIRMASI HAPUS MASSAL SERVER ===
                InkWell(
                  onTap: _selectedServerFiles.isEmpty
                      ? null
                      : () async {
                          // 1. Tampilkan dialog konfirmasi pop-up terlebih dahulu
                          final bool confirm =
                              await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: const [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Konfirmasi Hapus Masal'),
                                    ],
                                  ),
                                  content: Text(
                                    'Apakah Anda yakin ingin menghapus ${_selectedServerFiles.length} berkas cadangan dari server terpilih secara permanen?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text(
                                        'Batal',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          // 2. Jika ditekan 'Hapus' (confirm == true), jalankan penghapusan fisik
                          if (confirm) {
                            for (var file in _selectedServerFiles) {
                              if (await file.exists()) {
                                await file.delete();
                              }
                            }

                            // 3. Bersihkan penampung state
                            setState(() {
                              _selectedServerFiles.clear();
                              _isServerSelectionMode = false;
                            });

                            // 4. Picu pembaruan data di parent screen
                            widget.onDeleteServerBackup(
                              File('trigger_refresh_after_bulk_delete'),
                            );
                          }
                        },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedServerFiles.isEmpty
                          ? Colors.grey[200]
                          : Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedServerFiles.isEmpty
                            ? Colors.grey[300]!
                            : Colors.red.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.delete_sweep,
                      size: 18,
                      color: _selectedServerFiles.isEmpty
                          ? Colors.grey[400]
                          : Colors.red,
                    ),
                  ),
                ),

                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedServerFiles.clear();
                      _isServerSelectionMode = false;
                    });
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Menampilkan daftar berkas dari server
        widget.serverBackupFiles.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada file backup dari server.'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.serverBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = widget.serverBackupFiles[index];
                  final isSelected = _selectedServerFiles.contains(file);

                  return ListTile(
                    // Jika ditahan lama, aktifkan mode pemilihan massal dan otomatis centang file ini
                    onLongPress: () {
                      setState(() {
                        _isServerSelectionMode = true;
                        if (!isSelected) _selectedServerFiles.add(file);
                      });
                    },
                    // Ketukan biasa: Jika dalam mode edit maka lakukan centang, jika mode normal jalankan fungsi Restore
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
                        : () async {
                            // --- DIALOG KONFIRMASI RESTORE DARI SERVER ---
                            final bool confirm =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange[800],
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Restore Data Aplikasi?'),
                                      ],
                                    ),
                                    content: Text(
                                      'Apakah Anda yakin ingin memulihkan seluruh data menggunakan file cadangan server "${file.path.split('/').last}"?\n\n*Peringatan: Data aktif Anda saat ini akan sepenuhnya ditimpa.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text(
                                          'Batal',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Ya, Restore',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;

                            // Jika dikonfirmasi, panggil fungsi restore
                            if (confirm) {
                              widget.onRestoreAllZip(file);
                            }
                          },
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
                    // Sembunyikan tombol hapus satuan saat sedang memilih banyak file
                    trailing: _isServerSelectionMode
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => widget.onDeleteServerBackup(file),
                          ),
                  );
                },
              ),
      ],
    );
  }
}
