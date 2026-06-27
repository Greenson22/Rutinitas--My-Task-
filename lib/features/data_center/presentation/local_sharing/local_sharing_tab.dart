import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/last_restore_banner.dart'; // Sertakan impor banner
import 'sharing_server.dart';
import 'sharing_client.dart';

class LocalSharingTab extends StatefulWidget {
  final Map<String, String>? lastRestoreInfo; // Konstruktor tambahan
  final Function(File) onRestoreAllZip;
  final Function(bool) onLoadingStatusChanged;
  final VoidCallback onDataSynchronized;

  const LocalSharingTab({
    super.key,
    this.lastRestoreInfo,
    required this.onRestoreAllZip,
    required this.onLoadingStatusChanged,
    required this.onDataSynchronized,
  });

  @override
  State<LocalSharingTab> createState() => LocalSharingTabState();
}

class LocalSharingTabState extends State<LocalSharingTab> {
  final StorageService _storageService = StorageService();
  final SharingServer _sharingServer = SharingServer();
  final SharingClient _sharingClient = SharingClient();

  String _baseDir = 'Documents';
  List<File> _serverBackupFiles = [];
  bool _isServerSelectionMode = false;
  final List<File> _selectedServerFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
  }

  Future<void> _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      refreshServerBackups();
    }
  }

  Future<void> refreshServerBackups() async {
    List<File> files = await _storageService.getAllServerBackupFiles(_baseDir);
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() {
      _serverBackupFiles = files;
    });
  }

  String _getFormattedFileName(String prefix, String extension) {
    final now = DateTime.now();
    const daftarHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    String namaHari = daftarHari[now.weekday - 1];
    String tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String waktu =
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    return "${prefix}_${tanggal}_${namaHari}_$waktu.$extension";
  }

  Future<bool> _showConfirmDeleteDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Konfirmasi Hapus'),
              ],
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // MENAMPILKAN BANNER STATUS RESTORE TERAKHIR DI SINI
        LastRestoreBanner(lastRestoreInfo: widget.lastRestoreInfo),

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
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.cloud_upload)),
                  title: const Text('Mode Pengirim (Server)'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _sharingServer.startServer(
                        context: context,
                        baseDir: _baseDir,
                        getFormattedFileName: _getFormattedFileName,
                        onDataReceived: () {
                          refreshServerBackups();
                          widget.onDataSynchronized();
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text('Kirim File'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.cloud_download),
                  ),
                  title: const Text('Mode Penerima (Client)'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _sharingClient.showConnectDialog(
                        context: context,
                        baseDir: _baseDir,
                        getFormattedFileName: _getFormattedFileName,
                        onLoadingStatusChanged: widget.onLoadingStatusChanged,
                        onDataReceived: () {
                          refreshServerBackups();
                          widget.onDataSynchronized();
                        },
                      );
                    },
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
                    _selectedServerFiles.length == _serverBackupFiles.length
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 18,
                    color: Colors.teal[700],
                  ),
                  onPressed: () {
                    setState(() {
                      if (_selectedServerFiles.length ==
                          _serverBackupFiles.length) {
                        _selectedServerFiles.clear();
                      } else {
                        _selectedServerFiles.clear();
                        _selectedServerFiles.addAll(_serverBackupFiles);
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
                InkWell(
                  onTap: _selectedServerFiles.isEmpty
                      ? null
                      : () async {
                          final bool confirm = await _showConfirmDeleteDialog(
                            title: 'Konfirmasi Hapus Masal',
                            content:
                                'Apakah Anda yakin ingin menghapus ${_selectedServerFiles.length} berkas cadangan dari server terpilih secara permanen?',
                          );
                          if (confirm) {
                            for (var file in _selectedServerFiles) {
                              if (await file.exists()) await file.delete();
                            }
                            setState(() {
                              _selectedServerFiles.clear();
                              _isServerSelectionMode = false;
                            });
                            refreshServerBackups();
                          }
                        },
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
        _serverBackupFiles.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada file backup dari server.'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _serverBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = _serverBackupFiles[index];
                  final isSelected = _selectedServerFiles.contains(file);
                  final String fileName = file.path.split('/').last;

                  return ListTile(
                    onLongPress: () {
                      setState(() {
                        _isServerSelectionMode = true;
                        if (!isSelected) _selectedServerFiles.add(file);
                      });
                    },
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
                                      'Apakah Anda yakin ingin memulihkan seluruh data menggunakan file cadangan server "$fileName"?\n\n*Peringatan: Data aktif Anda saat ini akan sepenuhnya ditimpa.',
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
                            if (confirm) widget.onRestoreAllZip(file);
                          },
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
                    title: Text(fileName),
                    trailing: _isServerSelectionMode
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final bool
                              confirm = await _showConfirmDeleteDialog(
                                title: 'Hapus Berkas Server',
                                content:
                                    'Apakah Anda yakin ingin menghapus berkas "$fileName" ini secara permanen?',
                              );
                              if (confirm && await file.exists()) {
                                await file.delete();
                                refreshServerBackups();
                              }
                            },
                          ),
                  );
                },
              ),
      ],
    );
  }
}
