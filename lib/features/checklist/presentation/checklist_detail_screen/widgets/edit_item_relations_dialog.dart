import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/daily_model.dart';

class EditItemRelationsDialog extends StatefulWidget {
  final SubSubjectItem item;
  final DailySubject currentSubject;
  final List<DailySubject> allAvailableSubjects;
  final List<ChecklistGroup>? allAvailableGroups;
  final Function(List<SubSubjectItem> source, List<SubSubjectItem> destination)
  getAllItemsFlattened;
  final Function({
    required SubSubjectItem item,
    required String newName,
    required String? linkedSubjectId,
    required String? linkedSubjectName,
    required String? accumulatorItemId,
    required String? accumulatorItemName,
    required String? linkedExternalCardName,
    required String? linkedExternalItemId,
    required String? linkedExternalItemName,
    required int parsedCurrent,
    required int parsedTarget,
    required DailySubject? selectedExternalCard,
  })
  onConfirm;

  const EditItemRelationsDialog({
    super.key,
    required this.item,
    required this.currentSubject,
    required this.allAvailableSubjects,
    required this.allAvailableGroups,
    required this.getAllItemsFlattened,
    required this.onConfirm,
  });

  @override
  State<EditItemRelationsDialog> createState() =>
      _EditItemRelationsDialogState();
}

class _EditItemRelationsDialogState extends State<EditItemRelationsDialog> {
  late final TextEditingController _editController;
  late final TextEditingController _currentValController;
  late final TextEditingController _targetValController;

  ChecklistGroup? _selectedGroupTarget;
  List<DailySubject> _filteredCardTargets = [];
  String? _localLinkedTargetId;
  String? _localLinkedTarget;

  List<SubSubjectItem> _progressOptions = [];
  String? _localAccumulatorTargetId;
  String? _localAccumulatorTarget;
  DailySubject? _selectedExternalCard;
  List<SubSubjectItem> _externalCardProgressItems = [];
  String? _localExternalCardName;
  String? _localExternalItemId;
  String? _localExternalItemName;

  late final List<ChecklistGroup> _validGroupsList;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.item.subjectName);
    _currentValController = TextEditingController(
      text: widget.item.currentValue.toString(),
    );
    _targetValController = TextEditingController(
      text: widget.item.targetValue.toString(),
    );

    _localLinkedTargetId = widget.item.linkedSubjectId;
    _localLinkedTarget = widget.item.linkedSubjectName;
    _localAccumulatorTargetId = widget.item.accumulatorItemId;
    _localAccumulatorTarget = widget.item.accumulatorItemName;
    _localExternalCardName = widget.item.linkedExternalCardName;
    _localExternalItemId = widget.item.linkedExternalItemId;
    _localExternalItemName = widget.item.linkedExternalItemName;

    if (_localLinkedTarget != null && _localLinkedTarget!.isNotEmpty) {
      for (var group in widget.allAvailableGroups ?? <ChecklistGroup>[]) {
        for (var section in group.allList) {
          if (section.items.any(
            (sub) => sub.subjectName == _localLinkedTarget,
          )) {
            _selectedGroupTarget = group;
            for (var sec in group.allList) {
              _filteredCardTargets.addAll(sec.items);
            }
            break;
          }
        }
        if (_selectedGroupTarget != null) break;
      }
    }

    _validGroupsList = (widget.allAvailableGroups ?? <ChecklistGroup>[])
        .where((g) => !g.id.startsWith("CORRUPTED_"))
        .toList();

    List<SubSubjectItem> allFlattenedItems = [];
    widget.getAllItemsFlattened(
      widget.currentSubject.subMateri,
      allFlattenedItems,
    );
    _progressOptions = allFlattenedItems
        .where(
          (e) =>
              (e.itemType == 'progress' || e.itemType == 'countdown') &&
              e.id != widget.item.id,
        )
        .toList();

    if (_localAccumulatorTargetId != null) {
      final accItem = _progressOptions.firstWhere(
        (el) => el.id == _localAccumulatorTargetId,
        orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
      );
      if (accItem.subjectName.isNotEmpty) {
        _localAccumulatorTarget = accItem.subjectName;
      }
    }

    if (_localExternalCardName != null) {
      _selectedExternalCard = widget.allAvailableSubjects.firstWhere(
        (sub) => sub.subjectName == _localExternalCardName,
        orElse: () =>
            DailySubject(subjectName: '', progress: 'belum', subMateri: []),
      );
      if (_selectedExternalCard!.subjectName.isNotEmpty) {
        widget.getAllItemsFlattened(
          _selectedExternalCard!.subMateri,
          _externalCardProgressItems,
        );
        _externalCardProgressItems = _externalCardProgressItems
            .where(
              (el) => el.itemType == 'progress' || el.itemType == 'countdown',
            )
            .toList();

        if (_localExternalItemId != null) {
          final extItem = _externalCardProgressItems.firstWhere(
            (el) => el.id == _localExternalItemId,
            orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
          );
          if (extItem.subjectName.isNotEmpty) {
            _localExternalItemName = extItem.subjectName;
          }
        }
      } else {
        _selectedExternalCard = null;
      }
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _currentValController.dispose();
    _targetValController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ubah Item & Hubungan Lintas Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editController,
              decoration: const InputDecoration(
                labelText: 'Nama Sub-Materi',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.item.itemType == 'progress' ||
                widget.item.itemType == 'countdown') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _currentValController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: widget.item.itemType == 'countdown'
                            ? 'Sisa Nilai'
                            : 'Nilai Sekarang',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _targetValController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: widget.item.itemType == 'countdown'
                            ? 'Nilai Awal'
                            : 'Target Nilai',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '🔗 Kaitan Akumulasi Lintas Card Checklist',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DailySubject>(
              value: _selectedExternalCard,
              decoration: const InputDecoration(
                labelText: 'Pilih Card Checklist Target',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card_rounded),
              ),
              hint: const Text('Pilih Card Luar (Opsional)'),
              items: [
                const DropdownMenuItem<DailySubject>(
                  value: null,
                  child: Text('Tidak Dikaitkan Ke Card Lain'),
                ),
                ...widget.allAvailableSubjects
                    .where(
                      (sub) =>
                          sub.subjectName != widget.currentSubject.subjectName,
                    )
                    .map((sub) {
                      String displaySection =
                          (sub.section == 'focus' || sub.section.trim().isEmpty)
                          ? 'Seksi Utama'
                          : sub.section;
                      return DropdownMenuItem<DailySubject>(
                        value: sub,
                        child: Text(
                          '${sub.icon} ${sub.subjectName} (${displaySection.toUpperCase()})',
                        ),
                      );
                    }),
              ],
              onChanged: (DailySubject? targetCard) {
                setState(() {
                  _selectedExternalCard = targetCard;
                  _externalCardProgressItems.clear();
                  _localExternalCardName = targetCard?.subjectName;
                  _localExternalItemName = null;
                  if (targetCard != null) {
                    widget.getAllItemsFlattened(
                      targetCard.subMateri,
                      _externalCardProgressItems,
                    );
                    _externalCardProgressItems = _externalCardProgressItems
                        .where(
                          (el) =>
                              el.itemType == 'progress' ||
                              el.itemType == 'countdown',
                        )
                        .toList();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _localExternalItemId ??
                  (_externalCardProgressItems.any((el) => el.subjectName == _localExternalItemName)
                      ? _externalCardProgressItems
                          .firstWhere((el) => el.subjectName == _localExternalItemName)
                          .id
                      : null),
              disabledHint: const Text('Pilih Card target terlebih dahulu...'),
              decoration: InputDecoration(
                labelText: 'Pilih Item Angka Target',
                border: const OutlineInputBorder(),
                enabled:
                    _selectedExternalCard != null &&
                    _externalCardProgressItems.isNotEmpty,
                prefixIcon: const Icon(Icons.bar_chart_rounded),
              ),
              hint: Text(
                _selectedExternalCard == null
                    ? 'Pilih Card dulu'
                    : (_externalCardProgressItems.isEmpty
                          ? 'Tidak ada item progress/countdown'
                          : 'Pilih Item Target'),
              ),
              items: _selectedExternalCard == null
                  ? null
                  : [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tidak Dikaitkan Ke Item Tertentu'),
                      ),
                      ..._externalCardProgressItems.map(
                        (el) => DropdownMenuItem<String>(
                          value: el.id,
                          child: Text('Item: ${el.subjectName}'),
                        ),
                      ),
                    ],
              onChanged: _selectedExternalCard == null
                  ? null
                  : (String? val) {
                      setState(() {
                        _localExternalItemId = val;
                        if (val != null) {
                          final match = _externalCardProgressItems.firstWhere(
                            (el) => el.id == val,
                            orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
                          );
                          _localExternalItemName = match.subjectName.isNotEmpty ? match.subjectName : null;
                        } else {
                          _localExternalItemName = null;
                        }
                      });
                    },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '⚙️ Pengaturan Kaitan Internal & Prasyarat Kunci',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _localAccumulatorTargetId ??
                  (_progressOptions.any((opt) => opt.subjectName == _localAccumulatorTarget)
                      ? _progressOptions
                          .firstWhere((opt) => opt.subjectName == _localAccumulatorTarget)
                          .id
                      : null),
              decoration: const InputDecoration(
                labelText: 'Kaitkan Akumulasi Nilai Ke:',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.auto_graph_rounded),
              ),
              hint: const Text('Pilih List Pengumpul (Opsional)'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tidak Dikaitkan (Berdiri Sendiri)'),
                ),
                ..._progressOptions.map(
                  (opt) => DropdownMenuItem<String>(
                    value: opt.id,
                    child: Text('Kumpul ke: ${opt.subjectName}'),
                  ),
                ),
              ],
              onChanged: (String? val) {
                setState(() {
                  _localAccumulatorTargetId = val;
                  if (val != null) {
                    final match = _progressOptions.firstWhere(
                      (opt) => opt.id == val,
                      orElse: () => SubSubjectItem(subjectName: '', progress: 'belum'),
                    );
                    _localAccumulatorTarget = match.subjectName.isNotEmpty ? match.subjectName : null;
                  } else {
                    _localAccumulatorTarget = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            DropdownButtonFormField<ChecklistGroup>(
              value: _selectedGroupTarget,
              decoration: const InputDecoration(
                labelText: '1. Pilih Kelompok Grup',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group_work_outlined),
              ),
              hint: const Text('Pilih Grup Asal Card (Opsional)'),
              items: [
                const DropdownMenuItem<ChecklistGroup>(
                  value: null,
                  child: Text('Tidak Dikaitkan (Bebas Klik)'),
                ),
                ..._validGroupsList.map(
                  (group) => DropdownMenuItem(
                    value: group,
                    child: Text('${group.icon} ${group.groupName}'),
                  ),
                ),
              ],
              onChanged: (ChecklistGroup? targetGroup) {
                setState(() {
                  _selectedGroupTarget = targetGroup;
                  _filteredCardTargets.clear();
                  _localLinkedTargetId = null;
                  _localLinkedTarget = null;
                  if (targetGroup != null) {
                    for (var section in targetGroup.allList) {
                      _filteredCardTargets.addAll(section.items);
                    }
                    _filteredCardTargets.removeWhere(
                      (sub) =>
                          sub.subjectName == widget.currentSubject.subjectName,
                    );
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _localLinkedTarget,
              disabledHint: const Text(
                'Pilih kelompok grup terlebih dahulu...',
              ),
              decoration: InputDecoration(
                labelText: '2. Pilih Card Prasyarat',
                border: const OutlineInputBorder(),
                enabled:
                    _selectedGroupTarget != null &&
                    _filteredCardTargets.isNotEmpty,
                prefixIcon: const Icon(Icons.credit_card_rounded),
              ),
              hint: Text(
                _filteredCardTargets.isEmpty
                    ? 'Tidak ada card tersedia'
                    : 'Pilih Card Prasyarat',
              ),
              items: _selectedGroupTarget == null
                  ? null
                  : _filteredCardTargets
                        .map(
                          (sub) => DropdownMenuItem<String>(
                            value: sub.subjectName,
                            child: Text('Card: ${sub.subjectName}'),
                          ),
                        )
                        .toList(),
              onChanged: _selectedGroupTarget == null
                  ? null
                  : (String? val) => setState(() {
                        _localLinkedTarget = val;
                        // Catatan: DailySubject saat ini belum memiliki id, linkedSubjectId disimpan sama dengan val jika di-set
                        _localLinkedTargetId = val;
                      }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final newName = _editController.text.trim();
            if (newName.isNotEmpty) {
              final int parsedCurrent =
                  int.tryParse(_currentValController.text) ??
                  widget.item.currentValue;
              final int parsedTarget =
                  int.tryParse(_targetValController.text) ??
                  widget.item.targetValue;

              Navigator.pop(context);
              widget.onConfirm(
                item: widget.item,
                newName: newName,
                linkedSubjectId: _selectedGroupTarget == null
                    ? null
                    : _localLinkedTargetId,
                linkedSubjectName: _selectedGroupTarget == null
                    ? null
                    : _localLinkedTarget,
                accumulatorItemId: _localAccumulatorTargetId,
                accumulatorItemName: _localAccumulatorTarget,
                linkedExternalCardName: _selectedExternalCard == null
                    ? null
                    : _localExternalCardName,
                linkedExternalItemId: _selectedExternalCard == null
                    ? null
                    : _localExternalItemId,
                linkedExternalItemName: _selectedExternalCard == null
                    ? null
                    : _localExternalItemName,
                parsedCurrent: parsedCurrent,
                parsedTarget: parsedTarget,
                selectedExternalCard: _selectedExternalCard,
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
