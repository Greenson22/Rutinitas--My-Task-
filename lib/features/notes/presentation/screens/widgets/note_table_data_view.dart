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
  });

  @override
  State<NoteTableDataView> createState() => _NoteTableDataViewState();
}

class _NoteTableDataViewState extends State<NoteTableDataView> {
  bool _isFormVisible = false;

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
      widget.tableRows.add(newRow);
      _isFormVisible = false;
    });
    widget.onChanged();
  }

  Widget _buildInputField(String key, TextEditingController controller) {
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
            const Expanded(
              child: Center(
                child: Text(
                  'Buat kolom di tab Pengaturan Kolom terlebih dahulu.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
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
                      _isFormVisible ? 'Sembunyikan Form' : 'Tambah Data Baru',
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
                            sortColumnIndex: widget.sortColumnIndex,
                            sortAscending: widget.isAscending,
                            headingRowColor: MaterialStateProperty.resolveWith(
                              (states) => Colors.indigo.shade50,
                            ),
                            dataRowMinHeight: 50,
                            dataRowMaxHeight: 60,
                            columns: [
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
                                        columnIndex: columnIndex,
                                        currentSortColumnIndex:
                                            widget.sortColumnIndex,
                                        currentIsAscending: widget.isAscending,
                                        onSortUpdated: widget.onSortChanged,
                                      ),
                                );
                              }).toList(),
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
                                  ...widget.currentFieldKeys.map((key) {
                                    return DataCell(
                                      Container(
                                        width: 160,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: _buildInputField(key, row[key]!),
                                      ),
                                    );
                                  }).toList(),
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
