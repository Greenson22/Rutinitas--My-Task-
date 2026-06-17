// lib/features/daily/presentation/widgets/checklist_detail/checklist_tree_view.dart

import 'package:flutter/material.dart';
import '../../../data/models/daily_model.dart';

class ChecklistTreeView extends StatelessWidget {
  final SubSubjectItem item;
  final int depth;
  final bool isEditMode;
  final List<SubSubjectItem> selectedItems;
  final SubSubjectItem? highlightedItem;
  final bool isFirst;
  final bool isLast;
  final Function(SubSubjectItem, bool) onSelectItem;
  final Function(SubSubjectItem, int) onMoveOrder;
  final Function(SubSubjectItem) onEditName;
  final VoidCallback onLongPressToggle;
  final Function(SubSubjectItem, bool?) onCheckStatusChanged;
  final Function(SubSubjectItem) onTapToggleStatus;
  final Function(SubSubjectItem) onAddChild;
  final Function(SubSubjectItem) onDeleteItem;

  // Callback untuk kustomisasi Progress angka harian
  final Function(SubSubjectItem)? onToggleItemType;
  final Function(SubSubjectItem)? onUpdateProgressValue;

  // === CALLBACK BARU: Penangan aktivasi/nonaktivasi manual list ===
  final Function(SubSubjectItem)? onToggleDisable;

  const ChecklistTreeView({
    super.key,
    required this.item,
    required this.depth,
    required this.isEditMode,
    required this.selectedItems,
    required this.highlightedItem,
    required this.isFirst,
    required this.isLast,
    required this.onSelectItem,
    required this.onMoveOrder,
    required this.onEditName,
    required this.onLongPressToggle,
    required this.onCheckStatusChanged,
    required this.onTapToggleStatus,
    required this.onAddChild,
    required this.onDeleteItem,
    this.onToggleItemType,
    this.onUpdateProgressValue,
    this.onToggleDisable,
  });

  // Fungsi pembantu untuk memformat angka dengan separator titik ribuan Indonesia
  String _formatNumber(int number) {
    return number.toString().replaceAllWithRegExp(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      '.',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isChecked = item.progress == 'selesai';
    bool isCurrentlySelected = selectedItems.contains(item);
    bool isHighlighted = highlightedItem == item;
    double paddingLeft = (depth * 14.0).clamp(0.0, 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.amber.withOpacity(0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.fromLTRB(paddingLeft, 2, 4, 2),
          child: Row(
            children: [
              if (isEditMode) ...[
                Checkbox(
                  value: isCurrentlySelected,
                  activeColor: Colors.indigo,
                  onChanged: (bool? checked) =>
                      onSelectItem(item, checked == true),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  color: isFirst ? Colors.grey[300] : Colors.indigo,
                  onPressed: isFirst ? null : () => onMoveOrder(item, -1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  color: isLast ? Colors.grey[300] : Colors.indigo,
                  onPressed: isLast ? null : () => onMoveOrder(item, 1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: isEditMode
                    ? InkWell(
                        onTap: () => onEditName(item),
                        onLongPress: onLongPressToggle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            children: [
                              if (item.subMateri.isNotEmpty)
                                const Icon(
                                  Icons.account_tree_outlined,
                                  size: 16,
                                  color: Colors.indigo,
                                )
                              else if (item.itemType == 'progress')
                                const Icon(
                                  Icons.bar_chart_rounded,
                                  size: 16,
                                  color: Colors.deepOrange,
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.subjectName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: item.isDisabled
                                        ? Colors.red.shade400
                                        : Colors.black87,
                                    decoration: item.isDisabled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              // === TOMBOL DI MODE EDIT: Mengubah Status Aktif/Nonaktif List ===
                              IconButton(
                                icon: Icon(
                                  item.isDisabled
                                      ? Icons.block_flipped
                                      : Icons.check_circle_outline,
                                  color: item.isDisabled
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 18,
                                ),
                                tooltip: item.isDisabled
                                    ? 'Aktifkan Kembali'
                                    : 'Nonaktifkan List',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                onPressed: () => onToggleDisable?.call(item),
                              ),
                              if (item.subMateri.isEmpty &&
                                  onToggleItemType != null &&
                                  !item.isDisabled)
                                IconButton(
                                  icon: Icon(
                                    item.itemType == 'progress'
                                        ? Icons.toggle_on_rounded
                                        : Icons.toggle_off_outlined,
                                    color: item.itemType == 'progress'
                                        ? Colors.deepOrange
                                        : Colors.grey,
                                  ),
                                  tooltip: 'Ubah ke Tipe Progress',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  onPressed: () => onToggleItemType!(item),
                                ),
                              const Icon(
                                Icons.edit_note,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          // === RENDERING KONDISI NORMAL: Tanda Kali (X) jika dinonaktifkan, Checkbox jika normal ===
                          item.isDisabled
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded, // Gambar Kali / X
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                )
                              : Checkbox(
                                  value: isChecked,
                                  activeColor: item.itemType == 'progress'
                                      ? Colors.deepOrange
                                      : Colors.teal,
                                  onChanged: item.itemType == 'progress'
                                      ? (isChecked
                                            ? (bool? checked) =>
                                                  onCheckStatusChanged(
                                                    item,
                                                    checked,
                                                  )
                                            : null)
                                      : (bool? checked) =>
                                            onCheckStatusChanged(item, checked),
                                ),
                          Expanded(
                            child: InkWell(
                              // Mengunci jembatan aksi klik jika elemen berstatus dinonaktifkan
                              onTap: item.isDisabled
                                  ? null
                                  : () {
                                      if (item.itemType == 'progress') {
                                        onUpdateProgressValue?.call(item);
                                      } else {
                                        onTapToggleStatus(item);
                                      }
                                    },
                              onLongPress: onLongPressToggle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  item.subjectName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: item.isDisabled || isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.isDisabled
                                        ? Colors
                                              .red
                                              .shade300 // Merah pudar jika dinonaktifkan
                                        : (isChecked
                                              ? Colors.grey
                                              : Colors.black87),
                                    fontStyle: item.isDisabled
                                        ? FontStyle.italic
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // TAMPILAN INDIKATOR ANGKA PROGRES DENGAN FORMAT TITIK RIBUAN
                          if (item.itemType == 'progress' &&
                              item.subMateri.isEmpty &&
                              !item.isDisabled)
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: isChecked
                                      ? Colors.grey[200]
                                      : Colors.deepOrange.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 14,
                                  color: isChecked
                                      ? Colors.grey
                                      : Colors.deepOrange,
                                ),
                                label: Text(
                                  '${_formatNumber(item.currentValue)} / ${_formatNumber(item.targetValue)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isChecked
                                        ? Colors.grey
                                        : Colors.deepOrange[800],
                                  ),
                                ),
                                onPressed: () =>
                                    onUpdateProgressValue?.call(item),
                              ),
                            ),
                        ],
                      ),
              ),
              if (isEditMode) ...[
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.teal,
                    size: 18,
                  ),
                  onPressed: () => onAddChild(item),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  onPressed: () => onDeleteItem(item),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ],
          ),
        ),
        if (item.subMateri.isNotEmpty)
          Column(
            children: List.generate(item.subMateri.length, (index) {
              final child = item.subMateri[index];
              return ChecklistTreeView(
                item: child,
                depth: depth + 1,
                isEditMode: isEditMode,
                selectedItems: selectedItems,
                highlightedItem: highlightedItem,
                isFirst: index == 0,
                isLast: index == item.subMateri.length - 1,
                onSelectItem: onSelectItem,
                onMoveOrder: onMoveOrder,
                onEditName: onEditName,
                onLongPressToggle: onLongPressToggle,
                onCheckStatusChanged: onCheckStatusChanged,
                onTapToggleStatus: onTapToggleStatus,
                onAddChild: onAddChild,
                onDeleteItem: onDeleteItem,
                onToggleItemType: onToggleItemType,
                onUpdateProgressValue: onUpdateProgressValue,
                onToggleDisable:
                    onToggleDisable, // Rekursi untuk meneruskan callback ke cabang anak
              );
            }),
          ),
      ],
    );
  }
}

// Ekstensi sederhana untuk memformat RegExp string pengganti titik tanpa membutuhkan package tambahan
extension on String {
  String replaceAllWithRegExp(RegExp regExp, String replacement) {
    return this.replaceAllMapped(regExp, (match) => replacement);
  }
}
