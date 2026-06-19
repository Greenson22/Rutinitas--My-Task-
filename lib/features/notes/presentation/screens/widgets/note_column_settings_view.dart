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
  bool _isManageMode = false;

  final List<String> _availableTypes = [
    'String',
    'Numerik',
    'Date',
    'Time',
    'Pengingat',
    'Boolean',
    'Option', // <-- BARU: Menambahkan opsi tipe data baru
  ];

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
    final optionsController =
        TextEditingController(); // <-- BARU: Controller input opsi kustom
    String selectedType = 'String';
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
                  hintText: 'Nama Kolom (misal: Bank, No, Nama)',
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
                items: _availableTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedType = val);
                  }
                },
              ),
              // <-- BARU: Tampilkan input list pilihan hanya jika tipe 'Option' dipilih
              if (selectedType == 'Option') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Pilihan Opsi (Pisahkan dengan koma)',
                    hintText: 'Misal: BRI, BCA, Mandiri',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
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
                  String finalType = selectedType;

                  // Jika bertipe Option, format teks tipenya menjadi Option:BRI,BCA,Mandiri
                  if (selectedType == 'Option') {
                    final optionsText = optionsController.text.trim();
                    finalType = 'Option:$optionsText';
                  }

                  widget.controller.addFieldKey(
                    setDialogState: setState,
                    currentFieldKeys: widget.currentFieldKeys,
                    currentFieldTypes: widget.currentFieldTypes,
                    formControllers: widget.formControllers,
                    tableRows: widget.tableRows,
                    triggerChange: widget.onChanged,
                    key: key,
                    type: finalType,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Struktur Kolom Tabel:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isManageMode = !_isManageMode;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isManageMode ? Colors.teal : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: _isManageMode
                        ? Colors.teal.withOpacity(0.08)
                        : Colors.grey.shade50,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isManageMode
                            ? Icons.check_circle_outline
                            : Icons.settings_outlined,
                        size: 14,
                        color: _isManageMode ? Colors.teal : Colors.indigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isManageMode ? 'Selesai' : 'Kelola Kolom',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isManageMode ? Colors.teal : Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: widget.currentFieldKeys.length,
                    onReorder: (oldIndex, newIndex) {
                      widget.controller.moveFieldKey(
                        setDialogState: setState,
                        currentFieldKeys: widget.currentFieldKeys,
                        triggerChange: widget.onChanged,
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      );
                    },
                    itemBuilder: (ctx, idx) {
                      final key = widget.currentFieldKeys[idx];
                      final fullType =
                          widget.currentFieldTypes[key] ?? 'String';

                      // Membersihkan visual tipe data kustom di UI (misal 'Option:BRI,BCA' menjadi 'Option')
                      final displayType = fullType.split(':').first;

                      return Card(
                        key: ValueKey(key),
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (_isManageMode)
                                ReorderableDragStartListener(
                                  index: idx,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 10.0,
                                    ),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      color: Colors.grey,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
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
                                            value:
                                                displayType, // Gunakan displayType hasil parsing
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
                                            items: _availableTypes
                                                .map(
                                                  (t) => DropdownMenuItem(
                                                    value: t,
                                                    child: Text(t),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged:
                                                _isManageMode ||
                                                    displayType == 'Option'
                                                ? null // Kunci dropdown bawaan jika tipe Option agar datanya tidak rusak tanpa parameter list
                                                : (String? newType) {
                                                    if (newType != null &&
                                                        newType !=
                                                            displayType) {
                                                      widget.controller
                                                          .updateFieldType(
                                                            setDialogState:
                                                                setState,
                                                            currentFieldTypes:
                                                                widget
                                                                    .currentFieldTypes,
                                                            tableRows: widget
                                                                .tableRows,
                                                            triggerChange:
                                                                widget
                                                                    .onChanged,
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
                              if (_isManageMode)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Material(
                                      color: Colors.indigo.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () =>
                                            _showRenameFieldDialog(key),
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
          if (!_isManageMode)
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
