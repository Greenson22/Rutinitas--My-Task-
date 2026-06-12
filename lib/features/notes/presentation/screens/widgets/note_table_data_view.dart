// lib/features/notes/presentation/screens/widgets/note_table_data_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // STATE BARU: Melacak baris dan kolom ke berapa yang sedang aktif diedit di dalam tabel data tersimpan
  int? _editingRowIndex;
  String? _editingKey;

  // GLOBAL STATE BARU: Jika ini true, MAKA SEMUA BARIS akan menampilkan tombol aksi modifikasi
  bool _isManageModeGlobal = false;

  // BARU: Fungsi penentu apakah suatu baris memiliki kolom pengingat yang sudah jatuh tempo/lewat waktu
  bool _isRowOverdue(Map<String, TextEditingController> row) {
    for (var key in widget.currentFieldKeys) {
      final type = widget.currentFieldTypes[key];
      if (type == 'Pengingat') {
        final textValue = row[key]?.text.trim() ?? '';
        if (textValue.isNotEmpty && textValue != '-') {
          try {
            // Memparsing format 'YYYY-MM-DD HH:mm'
            final reminderDate = DateTime.parse(textValue);
            if (DateTime.now().isAfter(reminderDate)) {
              return true; // Waktu pengingat sudah lewat
            }
          } catch (_) {
            // Jika format gagal diparse, lewati
          }
        }
      }
    }
    return false;
  }

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

  // Helper untuk melakukan format DateTime ke String standar 'YYYY-MM-DD HH:mm'
  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // Helper Widget untuk membuat Opsi Durasi Cepat pada Pengingat berbasis startTime yang ditentukan
  Widget _buildDurationOption({
    required BuildContext dialogContext,
    required TextEditingController controller,
    required String title,
    required int daysToAdd,
    required DateTime startTime,
    required bool isFormInput,
  }) {
    return ListTile(
      leading: const Icon(Icons.more_time, color: Colors.indigo),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      dense: true,
      onTap: () {
        final DateTime calculatedDate = startTime.add(
          Duration(days: daysToAdd),
        );

        setState(() {
          // Format ke standar YYYY-MM-DD HH:mm agar sinkron dengan sistem overdue bawaan
          controller.text = _formatDateTime(calculatedDate);
          if (!isFormInput) {
            _editingRowIndex = null;
            _editingKey = null;
          }
        });
        widget.onChanged();
        Navigator.pop(dialogContext); // Tutup Dialog Utama pengingat
      },
    );
  }

  Widget _buildInputField(
    String key,
    TextEditingController controller, {
    int? rowIndex,
    bool isFormInput = false,
  }) {
    if (widget.isViewMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: SelectableText(
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
          : type ==
                'Pengingat' // BARU: Ikon untuk field Pengingat
          ? const Icon(
              Icons.notifications_active,
              size: 16,
              color: Colors.deepOrangeAccent,
            )
          : null,
    );

    if (!isFormInput && rowIndex != null) {
      final bool isCurrentEditing =
          (_editingRowIndex == rowIndex && _editingKey == key);

      if (!isCurrentEditing) {
        return InkWell(
          onTap: () {
            // Jika sedang dalam mode kelola global, matikan input ketikan teks biar fokus pindah baris
            if (_isManageModeGlobal) return;
            setState(() {
              _editingRowIndex = rowIndex;
              _editingKey = key;
            });
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            height: 35,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.transparent),
            ),
            child: Text(
              controller.text.isEmpty ? '-' : controller.text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

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
              if (!isFormInput) {
                _editingRowIndex = null;
                _editingKey = null;
              }
            });
            widget.onChanged();
          }
        },
      );
    }

    return TextField(
      controller: controller,
      keyboardType: type == 'Numerik'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: type == 'Numerik'
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      readOnly:
          type == 'Date' ||
          type == 'Time' ||
          type ==
              'Pengingat', // BARU: Pengingat diset readOnly agar diisi via Picker
      decoration: inputDecoration,
      style: const TextStyle(fontSize: 13),
      autofocus: !isFormInput,
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
              if (!isFormInput) {
                _editingRowIndex = null;
                _editingKey = null;
              }
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
              if (!isFormInput) {
                _editingRowIndex = null;
                _editingKey = null;
              }
            });
            widget.onChanged();
          }
        } else if (type == 'Pengingat') {
          // State awal waktu hitung dasar (default: waktu sekarang)
          DateTime reminderBaseTime = DateTime.now();
          final customDaysController = TextEditingController();

          showDialog(
            context: context,
            builder: (BuildContext ctx) {
              return StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text(
                      'Atur Waktu Pengingat',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // OPSI 1: Pilih Manual Tanggal dan Waktu Langsung Berdasarkan Pilihan
                          ListTile(
                            leading: const Icon(
                              Icons.edit_calendar,
                              color: Colors.teal,
                            ),
                            title: const Text(
                              'Pilih Tanggal & Waktu Manual',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () async {
                              Navigator.pop(ctx); // Tutup dialog utama

                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null && context.mounted) {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    controller.text = _formatDateTime(
                                      DateTime(
                                        pickedDate.year,
                                        pickedDate.month,
                                        pickedDate.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      ),
                                    );
                                    if (!isFormInput) {
                                      _editingRowIndex = null;
                                      _editingKey = null;
                                    }
                                  });
                                  widget.onChanged();
                                }
                              }
                            },
                          ),
                          const Divider(),

                          // BAGIAN KUSTOMISASI: WAKTU MULAI PERHITUNGAN (Default: Sekarang)
                          const Text(
                            'Waktu Mulai Perhitungan:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: reminderBaseTime,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null && context.mounted) {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    reminderBaseTime,
                                  ),
                                );
                                if (pickedTime != null) {
                                  setDialogState(() {
                                    reminderBaseTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.grey.shade100,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDateTime(reminderBaseTime),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.indigo,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),

                          // OPSI: Tambah Hari Kustom via Field Input Angka
                          const Text(
                            'Tambah Hari Kustom:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: customDaysController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Contoh: 7',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final text = customDaysController.text.trim();
                                  if (text.isNotEmpty) {
                                    final days = int.tryParse(text) ?? 0;
                                    final calculatedDate = reminderBaseTime.add(
                                      Duration(days: days),
                                    );
                                    setState(() {
                                      controller.text = _formatDateTime(
                                        calculatedDate,
                                      );
                                      if (!isFormInput) {
                                        _editingRowIndex = null;
                                        _editingKey = null;
                                      }
                                    });
                                    widget.onChanged();
                                    Navigator.pop(ctx);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  visualDensity: VisualDensity
                                      .compact, // FIXED: Menggantikan properti dense yang undefined
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Tambah',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),

                          // OPSI: Pilihan Durasi Cepat (Otomatis berdasarkan waktu awal kalkulasi)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Opsi Durasi Instan Bulanan/Tahunan:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          _buildDurationOption(
                            dialogContext: ctx,
                            controller: controller,
                            title: 'Tambahkan 1 Bulan',
                            daysToAdd: 30,
                            startTime: reminderBaseTime,
                            isFormInput: isFormInput,
                          ),
                          _buildDurationOption(
                            dialogContext: ctx,
                            controller: controller,
                            title: 'Tambahkan 3 Bulan',
                            daysToAdd: 90,
                            startTime: reminderBaseTime,
                            isFormInput: isFormInput,
                          ),
                          _buildDurationOption(
                            dialogContext: ctx,
                            controller: controller,
                            title: 'Tambahkan 6 Bulan',
                            daysToAdd: 180,
                            startTime: reminderBaseTime,
                            isFormInput: isFormInput,
                          ),
                          _buildDurationOption(
                            dialogContext: ctx,
                            controller: controller,
                            title: 'Tambahkan 1 Tahun',
                            daysToAdd: 365,
                            startTime: reminderBaseTime,
                            isFormInput: isFormInput,
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      },
      onTapOutside: (_) {
        FocusScope.of(context).unfocus();
        if (!isFormInput) {
          setState(() {
            _editingRowIndex = null;
            _editingKey = null;
          });
        }
      },
      onChanged: (_) => widget.onChanged(),
      onSubmitted: (_) {
        if (!isFormInput) {
          setState(() {
            _editingRowIndex = null;
            _editingKey = null;
          });
        }
      },
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
                                          isFormInput: true,
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

              // Header Pengelola Global
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Data Tersimpan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isManageModeGlobal = !_isManageModeGlobal;
                        if (_isManageModeGlobal) {
                          _editingRowIndex = null;
                          _editingKey = null;
                        }
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
                          color: _isManageModeGlobal
                              ? Colors.teal
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: _isManageModeGlobal
                            ? Colors.teal.withOpacity(0.08)
                            : Colors.grey.shade50,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isManageModeGlobal
                                ? Icons.check_circle_outline
                                : Icons.settings_outlined,
                            size: 14,
                            color: _isManageModeGlobal
                                ? Colors.teal
                                : Colors.indigo,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isManageModeGlobal ? 'Selesai' : 'Kelola Urutan',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isManageModeGlobal
                                  ? Colors.teal
                                  : Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: DataTable(
                                  horizontalMargin: 12,
                                  columnSpacing: 24,
                                  sortColumnIndex:
                                      widget.sortColumnIndex != null
                                      ? widget.sortColumnIndex! + 1
                                      : null,
                                  sortAscending: widget.isAscending,
                                  headingRowColor:
                                      MaterialStateProperty.resolveWith(
                                        (states) => Colors.indigo.shade50,
                                      ),
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: widget.isViewMode ? 50 : 60,
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
                                              currentIsAscending:
                                                  widget.isAscending,
                                              onSortUpdated:
                                                  widget.onSortChanged,
                                            ),
                                      );
                                    }).toList(),
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
                                  rows: widget.tableRows.asMap().entries.map((
                                    entry,
                                  ) {
                                    int index = entry.key;
                                    var row = entry.value;

                                    // BARU: Cek apakah baris ini memiliki pengingat yang lewat waktu/jatuh tempo
                                    final bool isOverdue = _isRowOverdue(row);

                                    return DataRow(
                                      // BARU: Mengubah warna latar belakang baris menjadi merah muda jika sudah lewat/jatuh tempo
                                      color: MaterialStateProperty.resolveWith<Color?>((
                                        Set<MaterialState> states,
                                      ) {
                                        if (isOverdue) {
                                          return Colors
                                              .red
                                              .shade50; // Latar belakang merah lembut
                                        }
                                        return null; // Gunakan warna default bawaan sistem
                                      }),
                                      cells: [
                                        DataCell(
                                          Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              // Jika lewat, warnai teks angka penunjuk nomornya menjadi merah tua
                                              color: isOverdue
                                                  ? Colors.red.shade900
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        ...widget.currentFieldKeys.map((key) {
                                          return DataCell(
                                            Container(
                                              width: widget.isViewMode
                                                  ? null
                                                  : 160,
                                              padding: EdgeInsets.symmetric(
                                                vertical: widget.isViewMode
                                                    ? 0
                                                    : 4,
                                              ),
                                              child: _buildInputField(
                                                key,
                                                row[key]!,
                                                rowIndex: index,
                                                isFormInput: false,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        if (!widget.isViewMode)
                                          DataCell(
                                            _isManageModeGlobal
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // 1. Tombol Pindah Naik
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .arrow_upward_rounded,
                                                          color: Colors.blue,
                                                          size: 18,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        onPressed: index == 0
                                                            ? null
                                                            : () => widget.controller.moveRow(
                                                                setDialogState:
                                                                    setState,
                                                                tableRows: widget
                                                                    .tableRows,
                                                                triggerChange:
                                                                    widget
                                                                        .onChanged,
                                                                currentIndex:
                                                                    index,
                                                                moveUp: true,
                                                              ),
                                                        tooltip:
                                                            'Pindah Ke Atas',
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // 2. Tombol Pindah Turun
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .arrow_downward_rounded,
                                                          color: Colors.blue,
                                                          size: 18,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        onPressed:
                                                            index ==
                                                                widget
                                                                        .tableRows
                                                                        .length -
                                                                    1
                                                            ? null
                                                            : () => widget.controller.moveRow(
                                                                setDialogState:
                                                                    setState,
                                                                tableRows: widget
                                                                    .tableRows,
                                                                triggerChange:
                                                                    widget
                                                                        .onChanged,
                                                                currentIndex:
                                                                    index,
                                                                moveUp: false,
                                                              ),
                                                        tooltip:
                                                            'Pindah Ke Bawah',
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // 3. Tombol Hapus Baris
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                          color:
                                                              Colors.redAccent,
                                                          size: 18,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        onPressed: () => widget
                                                            .controller
                                                            .removeRow(
                                                              setDialogState:
                                                                  setState,
                                                              tableRows: widget
                                                                  .tableRows,
                                                              triggerChange:
                                                                  widget
                                                                      .onChanged,
                                                              index: index,
                                                            ),
                                                        tooltip: 'Hapus Baris',
                                                      ),
                                                    ],
                                                  )
                                                : const Text(
                                                    '-',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
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
