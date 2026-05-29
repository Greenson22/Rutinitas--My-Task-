import 'dart:io';
import 'package:flutter/material.dart';

class BackupTab extends StatefulWidget {
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
  final List<File> serverBackupFiles;
  final Function(File) onDeleteServerBackup;

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
  State<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<BackupTab> {
  // 1. Deklarasi variabel state diletakkan di sini
  bool _isSelectionMode = false;
  final List<File> _selectedFiles = [];

  // 2. Fungsi build dipindahkan ke dalam State
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
                widget
                    .onBackupTaskMaster, // Menggunakan widget. untuk memanggil parameter
                widget.onRestoreTaskMaster,
              ),
              _buildCompactButton(
                'Checklist',
                Icons.checklist_rtl,
                widget.onBackupChecklist,
                widget.onRestoreChecklist,
              ),
              _buildCompactButton(
                'Jurnal',
                Icons.menu_book,
                widget.onBackupJurnal,
                widget.onRestoreJurnal,
              ),
            ],
          ),
        ),

        const Divider(thickness: 2),

        // Bagian Header Daftar Berkas & Tombol Dinamis
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
                    if (_isSelectionMode) ...[
                      Text(
                        '${_selectedFiles.length} Terpilih  ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectedFiles.isEmpty
                            ? null
                            : () async {
                                for (var file in _selectedFiles) {
                                  widget.onDeleteBackup(file);
                                }
                                setState(() {
                                  _selectedFiles.clear();
                                  _isSelectionMode = false;
                                });
                              },
                        icon: const Icon(Icons.delete_sweep, size: 16),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFiles.clear();
                            _isSelectionMode = false;
                          });
                        },
                        child: const Text('Batal'),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: widget.onRestoreAllZip,
                        icon: const Icon(Icons.unarchive, size: 16),
                        label: const Text(
                          'Import',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: widget.onCreateBackup,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Backup',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Daftar File ZIP Lokal dengan Checkbox & Mode Tahan Lama
        widget.localBackupFiles.isEmpty
            ? const Center(child: Text('Belum ada file backup.'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.localBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = widget.localBackupFiles[index];
                  final isSelected = _selectedFiles.contains(file);

                  return ListTile(
                    onLongPress: () {
                      setState(() {
                        _isSelectionMode = true;
                        if (!isSelected) _selectedFiles.add(file);
                      });
                    },
                    onTap: _isSelectionMode
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedFiles.remove(file);
                              } else {
                                _selectedFiles.add(file);
                              }
                            });
                          }
                        : null,
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            activeColor: Colors.red,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedFiles.add(file);
                                } else {
                                  _selectedFiles.remove(file);
                                }
                              });
                            },
                          )
                        : const Icon(Icons.folder_zip, color: Colors.amber),
                    title: Text(file.path.split('/').last),
                    trailing: _isSelectionMode
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => widget.onDeleteBackup(file),
                          ),
                  );
                },
              ),
      ],
    );
  }

  // 3. Helper widget dipindahkan ke dalam State agar rapi
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: onUp,
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.cloud_download_outlined,
                color: Colors.green,
                size: 20,
              ),
              onPressed: onDown,
            ),
          ],
        ),
      ],
    );
  }
}
