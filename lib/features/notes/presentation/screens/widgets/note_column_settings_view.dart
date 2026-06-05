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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "Tipe Data: $type",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => widget.controller.removeFieldKey(
                              setDialogState: setState,
                              currentFieldKeys: widget.currentFieldKeys,
                              currentFieldTypes: widget.currentFieldTypes,
                              formControllers: widget.formControllers,
                              tableRows: widget.tableRows,
                              triggerChange: widget.onChanged,
                              key: key,
                            ),
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
