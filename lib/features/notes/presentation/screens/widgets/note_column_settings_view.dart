// lib/features/notes/presentation/screens/widgets/note_column_settings_view.dart
import 'package:flutter/material.dart';
import '../../controllers/note_detail_controller.dart';

class NoteColumnSettingsView extends StatefulWidget {
  final NoteDetailController controller;
  final List<String> currentFieldKeys;
  final Map<String, String> currentFieldTypes;
  final List<Map<String, TextEditingController>> tableRows;
  final Map<String, TextEditingController> formControllers;
  final VoidCallback onChanged;

  const NoteColumnSettingsView({
    super.key,
    required this.controller,
    required this.currentFieldKeys,
    required this.currentFieldTypes,
    required this.tableRows,
    required this.formControllers,
    required this.onChanged,
  });

  @override
  State<NoteColumnSettingsView> createState() => _NoteColumnSettingsViewState();
}

class _NoteColumnSettingsViewState extends State<NoteColumnSettingsView> {
  // BARU: Dialog pop-up untuk mengubah nama kolom yang ada
  void _showRenameFieldDialog(String oldKey) {
    final renameController = TextEditingController(text: oldKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Kolom'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(labelText: 'Nama Kolom Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final String newKey = renameController.text.trim();
              if (newKey.isNotEmpty && newKey != oldKey) {
                widget.controller.renameFieldKey(
                  setDialogState: setState,
                  currentFieldKeys: widget.currentFieldKeys,
                  currentFieldTypes: widget.currentFieldTypes,
                  formControllers: widget.formControllers,
                  tableRows: widget.tableRows,
                  triggerChange: widget.onChanged,
                  oldKey: oldKey,
                  newKey: newKey,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddFieldDialog() {
    final keyController = TextEditingController();
    String selectedType = 'String';
    final List<String> availableTypes = [
      'String',
      'Numerik',
      'Date',
      'Time',
      'Boolean',
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctxModal, setModalState) => AlertDialog(
          title: const Text('Tambah Kolom Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  hintText: 'Nama Kolom (misal: No, Nama, Tanggal)',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Data Kolom',
                  border: OutlineInputBorder(),
                ),
                items: availableTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedType = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final key = keyController.text.trim();
                if (key.isNotEmpty) {
                  widget.controller.addFieldKey(
                    setDialogState: setState,
                    currentFieldKeys: widget.currentFieldKeys,
                    currentFieldTypes: widget.currentFieldTypes,
                    formControllers: widget.formControllers,
                    tableRows: widget.tableRows,
                    triggerChange: widget.onChanged,
                    key: key,
                    type: selectedType,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Definisikan Struktur Kolom Tabel:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.currentFieldKeys.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada kolom dibuat.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.currentFieldKeys.length,
                    itemBuilder: (ctx, idx) {
                      final key = widget.currentFieldKeys[idx];
                      final type = widget.currentFieldTypes[key] ?? 'String';
                      final List<String> availableTypes = [
                        'String',
                        'Numerik',
                        'Date',
                        'Time',
                        'Boolean',
                      ];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0, // Desain flat modern
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // SISI KIRI: Detail Kolom (Nama & Dropdown Tipe)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      key,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          "Tipe: ",
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Theme(
                                          data: Theme.of(
                                            context,
                                          ).copyWith(canvasColor: Colors.white),
                                          child: DropdownButton<String>(
                                            value: type,
                                            isDense: true,
                                            underline: const SizedBox(),
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              size: 18,
                                              color: Colors.indigo,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.indigo,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            items: availableTypes
                                                .map(
                                                  (t) => DropdownMenuItem(
                                                    value: t,
                                                    child: Text(t),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (String? newType) {
                                              if (newType != null &&
                                                  newType != type) {
                                                widget.controller
                                                    .updateFieldType(
                                                      setDialogState: setState,
                                                      currentFieldTypes: widget
                                                          .currentFieldTypes,
                                                      tableRows:
                                                          widget.tableRows,
                                                      triggerChange:
                                                          widget.onChanged,
                                                      key: key,
                                                      newType: newType,
                                                    );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // SISI KANAN: Tombol Aksi Bersih
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol Edit Nama Kolom
                                  Material(
                                    color: Colors.indigo.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      onTap: () => _showRenameFieldDialog(key),
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Tombol Hapus Kolom
                                  Material(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      onTap: () =>
                                          widget.controller.removeFieldKey(
                                            setDialogState: setState,
                                            currentFieldKeys:
                                                widget.currentFieldKeys,
                                            currentFieldTypes:
                                                widget.currentFieldTypes,
                                            formControllers:
                                                widget.formControllers,
                                            tableRows: widget.tableRows,
                                            triggerChange: widget.onChanged,
                                            key: key,
                                          ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddFieldDialog,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                'Tambah Kolom Baru',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            ),
          ),
        ],
      ),
    );
  }
}
