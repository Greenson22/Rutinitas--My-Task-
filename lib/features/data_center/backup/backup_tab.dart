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
  // === TAMBAHAN: Callback untuk Notes & Prompts ===
  final VoidCallback onBackupNotes;
  final VoidCallback onRestoreNotes;
  final VoidCallback onBackupPrompts;
  final VoidCallback onRestorePrompts;
  // ================================================
  final Function(File) onRestoreAllZip;
  final List<File> serverBackupFiles;
  final Function(File) onDeleteServerBackup;
  final VoidCallback onImportZip;
  final Function(File) onExportToFolder;

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
    required this.onBackupNotes,
    required this.onRestoreNotes,
    required this.onBackupPrompts,
    required this.onRestorePrompts,
    required this.onRestoreAllZip,
    required this.serverBackupFiles,
    required this.onDeleteServerBackup,
    required this.onImportZip,
    required this.onExportToFolder,
  });

  @override
  State<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<BackupTab> {
  bool _isSelectionMode = false;
  final List<File> _selectedFiles = [];

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
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Baris Tombol Ringkas (Task Master, Checklist, Jurnal, Notes, Prompts)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          // PERBAIKAN: Menggunakan SingleChildScrollView agar tidak overflow jika layar kecil
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactButton(
                  'Task Master',
                  Icons.format_list_bulleted,
                  widget.onBackupTaskMaster,
                  widget.onRestoreTaskMaster,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Checklist',
                  Icons.checklist_rtl,
                  widget.onBackupChecklist,
                  widget.onRestoreChecklist,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Jurnal',
                  Icons.menu_book,
                  widget.onBackupJurnal,
                  widget.onRestoreJurnal,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Notes',
                  Icons.note_alt,
                  widget.onBackupNotes,
                  widget.onRestoreNotes,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Prompts',
                  Icons.smart_toy,
                  widget.onBackupPrompts,
                  widget.onRestorePrompts,
                ),
              ],
            ),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              FittedBox(
                child: Row(
                  children: [
                    if (_isSelectionMode) ...[
                      IconButton(
                        icon: Icon(
                          _selectedFiles.length ==
                                  widget.localBackupFiles.length
                              ? Icons.deselect
                              : Icons.select_all,
                          size: 18,
                          color: Colors.teal[700],
                        ),
                        tooltip:
                            _selectedFiles.length ==
                                widget.localBackupFiles.length
                            ? 'Batal Semua'
                            : 'Pilih Semua',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        onPressed: () {
                          setState(() {
                            if (_selectedFiles.length ==
                                widget.localBackupFiles.length) {
                              _selectedFiles.clear();
                            } else {
                              _selectedFiles.clear();
                              _selectedFiles.addAll(widget.localBackupFiles);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedFiles.length} Terpilih',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _selectedFiles.isEmpty
                            ? null
                            : () async {
                                final bool
                                confirm = await _showConfirmDeleteDialog(
                                  title: 'Hapus Masal',
                                  content:
                                      'Apakah Anda yakin ingin menghapus ${_selectedFiles.length} berkas cadangan terpilih secara permanen?',
                                );
                                if (confirm) {
                                  for (var file in _selectedFiles) {
                                    widget.onDeleteBackup(file);
                                  }
                                  setState(() {
                                    _selectedFiles.clear();
                                    _isSelectionMode = false;
                                  });
                                }
                              },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedFiles.isEmpty
                                ? Colors.grey[200]
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _selectedFiles.isEmpty
                                  ? Colors.grey[300]!
                                  : Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_sweep,
                            size: 18,
                            color: _selectedFiles.isEmpty
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
                            _selectedFiles.clear();
                            _isSelectionMode = false;
                          });
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: widget.onImportZip,
                        icon: const Icon(Icons.unarchive, size: 14),
                        label: const Text(
                          'Import',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: widget.onCreateBackup,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Backup',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Daftar File ZIP Lokal
        widget.localBackupFiles.isEmpty
            ? const Center(child: Text('Belum ada file backup.'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.localBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = widget.localBackupFiles[index];
                  final isSelected = _selectedFiles.contains(file);
                  final String fileName = file.path.split('/').last;
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
                                      'Apakah Anda yakin ingin memulihkan seluruh data menggunakan file cadangan "$fileName"?\n\n*Peringatan: Data aktif Anda saat ini akan sepenuhnya ditimpa.',
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
                            if (confirm) {
                              widget.onRestoreAllZip(file);
                            }
                          },
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
                    title: Text(fileName),
                    trailing: _isSelectionMode
                        ? null
                        : PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              if (value == 'export_folder') {
                                widget.onExportToFolder(file);
                              } else if (value == 'delete_backup') {
                                final bool
                                confirm = await _showConfirmDeleteDialog(
                                  title: 'Hapus Berkas Backup',
                                  content:
                                      'Apakah Anda yakin ingin menghapus berkas cadangan "$fileName" secara permanen?',
                                );
                                if (confirm) {
                                  widget.onDeleteBackup(file);
                                }
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'export_folder',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.drive_file_move,
                                    color: Colors.indigo,
                                    size: 20,
                                  ),
                                  title: Text('Simpan ke Folder Kustom'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'delete_backup',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  title: Text(
                                    'Hapus Permanen',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildCompactButton(
    String label,
    IconData icon,
    VoidCallback onUp,
    VoidCallback onDown,
  ) {
    return Column(
      children: [
        CircleAvatar(child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 4),
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
