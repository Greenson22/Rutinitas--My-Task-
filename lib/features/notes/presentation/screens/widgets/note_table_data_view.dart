// lib/features/notes/presentation/screens/widgets/note_table_data_view.dart
import 'package:flutter/material.dart';
import '../../controllers/note_detail_controller.dart';

class NoteTableDataView extends StatefulWidget {
  final NoteDetailController controller;
  final List<String> currentFieldKeys;
  final Map<String, String> currentFieldTypes;
  final List<Map<String, TextEditingController>> tableRows;
  final Map<String, TextEditingController> formControllers;
  final int? sortColumnIndex;
  final bool isAscending;
  final VoidCallback onChanged;
  final Function(int?, bool) onSortChanged;
  final bool isViewMode; // BARU: Menerima state isViewMode

  const NoteTableDataView({
    super.key,
    required this.controller,
    required this.currentFieldKeys,
    required this.currentFieldTypes,
    required this.tableRows,
    required this.formControllers,
    required this.sortColumnIndex,
    required this.isAscending,
    required this.onChanged,
    required this.onSortChanged,
    this.isViewMode = false, // BARU
  });

  @override
  State<NoteTableDataView> createState() => _NoteTableDataViewState();
}

class _NoteTableDataViewState extends State<NoteTableDataView> {
  bool _isFormVisible = false;

  String _insertPosition = 'Paling Bawah';
  int _targetRowIndex = 0;

  void _submitFormRow() {
    setState(() {
      Map<String, TextEditingController> newRow = {};
      for (var key in widget.currentFieldKeys) {
        newRow[key] = TextEditingController(
          text: widget.formControllers[key]?.text.trim() ?? '',
        );
        widget.formControllers[key]?.text =
            widget.currentFieldTypes[key] == 'Boolean' ? 'Tidak' : '';
      }

      if (_insertPosition == 'Paling Atas') {
        widget.tableRows.insert(0, newRow);
      } else if (_insertPosition == 'Setelah Baris Tertentu' &&
          widget.tableRows.isNotEmpty) {
        int insertIndex = _targetRowIndex + 1;
        if (insertIndex >= widget.tableRows.length) {
          widget.tableRows.add(newRow);
        } else {
          widget.tableRows.insert(insertIndex, newRow);
        }
      } else {
        widget.tableRows.add(newRow);
      }

      _isFormVisible = false;
    });
    widget.onChanged();
  }

  Widget _buildInputField(String key, TextEditingController controller) {
    // BARU: Jika di mode view, cukup render Text biasa (tanpa TextField / Dropdown)
    if (widget.isViewMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Text(
          controller.text.isEmpty ? '-' : controller.text,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      );
    }

    String type = widget.currentFieldTypes[key] ?? 'String';
    InputDecoration inputDecoration = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      suffixIcon: type == 'Date'
          ? const Icon(Icons.calendar_today, size: 16, color: Colors.indigo)
          : type == 'Time'
          ? const Icon(Icons.access_time, size: 16, color: Colors.indigo)
          : null,
    );

    if (type == 'Boolean') {
      if (controller.text != 'Ya' && controller.text != 'Tidak') {
        controller.text = 'Tidak';
      }
      return DropdownButtonFormField<String>(
        value: controller.text,
        decoration: inputDecoration,
        style: const TextStyle(fontSize: 13, color: Colors.black),
        items: const [
          DropdownMenuItem(value: 'Ya', child: Text('Ya')),
          DropdownMenuItem(value: 'Tidak', child: Text('Tidak')),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() {
              controller.text = val;
            });
            widget.onChanged();
          }
        },
      );
    }

    return TextField(
      controller: controller,
      keyboardType: type == 'Numerik'
          ? TextInputType.number
          : TextInputType.text,
      readOnly: type == 'Date' || type == 'Time',
      decoration: inputDecoration,
      style: const TextStyle(fontSize: 13),
      onTap: () async {
        if (type == 'Date') {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              controller.text =
                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
            });
            widget.onChanged();
          }
        } else if (type == 'Time') {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null) {
            setState(() {
              controller.text =
                  "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
            });
            widget.onChanged();
          }
        }
      },
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onChanged: (_) => widget.onChanged(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.currentFieldKeys.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  widget.isViewMode
                      ? 'Tabel tidak memiliki kolom.'
                      : 'Buat kolom di tab Pengaturan Kolom terlebih dahulu.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            // BARU: Sembunyikan blok 'Tambah Data Baru' jika dalam View Mode
            if (!widget.isViewMode) ...[
              InkWell(
                onTap: () => setState(() => _isFormVisible = !_isFormVisible),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isFormVisible
                        ? Colors.indigo.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isFormVisible
                            ? Icons.keyboard_arrow_up
                            : Icons.add_circle_outline,
                        color: Colors.indigo,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFormVisible
                            ? 'Sembunyikan Form'
                            : 'Tambah Data Baru',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: !_isFormVisible
                    ? const SizedBox.shrink()
                    : Card(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Input Data Baru',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const Divider(),
                              ...widget.currentFieldKeys.map((key) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          "$key (${widget.currentFieldTypes[key] ?? 'String'})",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildInputField(
                                          key,
                                          widget.formControllers[key]!,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 8),
                              const Text(
                                'Posisi Sisip Data:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: _insertPosition,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Paling Bawah',
                                          child: Text('Paling Bawah'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Paling Atas',
                                          child: Text('Paling Atas'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Setelah Baris Tertentu',
                                          child: Text('Setelah Baris...'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null)
                                          setState(() => _insertPosition = val);
                                      },
                                    ),
                                  ),
                                  if (_insertPosition ==
                                          'Setelah Baris Tertentu' &&
                                      widget.tableRows.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<int>(
                                        value:
                                            _targetRowIndex <
                                                widget.tableRows.length
                                            ? _targetRowIndex
                                            : 0,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                        items: List.generate(
                                          widget.tableRows.length,
                                          (i) {
                                            return DropdownMenuItem(
                                              value: i,
                                              child: Text('Baris ${i + 1}'),
                                            );
                                          },
                                        ),
                                        onChanged: (val) {
                                          if (val != null)
                                            setState(
                                              () => _targetRowIndex = val,
                                            );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _submitFormRow,
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Simpan ke Tabel',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Daftar Data Tersimpan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Expanded(
              child: widget.tableRows.isEmpty
                  ? const Center(
                      child: Text(
                        'Tabel masih kosong.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            sortColumnIndex: widget.sortColumnIndex != null
                                ? widget.sortColumnIndex! + 1
                                : null,
                            sortAscending: widget.isAscending,
                            headingRowColor: MaterialStateProperty.resolveWith(
                              (states) => Colors.indigo.shade50,
                            ),
                            dataRowMinHeight: 50,
                            dataRowMaxHeight: widget.isViewMode
                                ? 50
                                : 60, // Sedikit lebih ramping di mode view
                            columns: [
                              const DataColumn(
                                label: Text(
                                  'No.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                              ...widget.currentFieldKeys.asMap().entries.map((
                                entry,
                              ) {
                                String key = entry.value;
                                return DataColumn(
                                  label: Text(
                                    "$key (${widget.currentFieldTypes[key] ?? 'String'})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  onSort: (columnIndex, ascending) =>
                                      widget.controller.sortTable(
                                        setDialogState: setState,
                                        tableRows: widget.tableRows,
                                        currentFieldTypes:
                                            widget.currentFieldTypes,
                                        triggerChange: widget.onChanged,
                                        key: key,
                                        columnIndex: columnIndex - 1,
                                        currentSortColumnIndex:
                                            widget.sortColumnIndex,
                                        currentIsAscending: widget.isAscending,
                                        onSortUpdated: widget.onSortChanged,
                                      ),
                                );
                              }).toList(),

                              // BARU: Sembunyikan kolom "Aksi" jika sedang View Mode
                              if (!widget.isViewMode)
                                const DataColumn(
                                  label: Text(
                                    'Aksi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                            ],
                            rows: widget.tableRows.asMap().entries.map((entry) {
                              int index = entry.key;
                              var row = entry.value;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ...widget.currentFieldKeys.map((key) {
                                    return DataCell(
                                      Container(
                                        width: widget.isViewMode ? null : 160,
                                        padding: EdgeInsets.symmetric(
                                          vertical: widget.isViewMode ? 0 : 4,
                                        ),
                                        child: _buildInputField(key, row[key]!),
                                      ),
                                    );
                                  }).toList(),

                                  // BARU: Sembunyikan icon hapus baris jika sedang View Mode
                                  if (!widget.isViewMode)
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            widget.controller.removeRow(
                                              setDialogState: setState,
                                              tableRows: widget.tableRows,
                                              triggerChange: widget.onChanged,
                                              index: index,
                                            ),
                                        tooltip: 'Hapus Baris',
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
