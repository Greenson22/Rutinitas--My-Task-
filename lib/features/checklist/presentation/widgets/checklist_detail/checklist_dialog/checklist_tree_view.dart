// lib/features/daily/presentation/widgets/checklist_detail/checklist_dialog/checklist_tree_view.dart

import 'package:flutter/material.dart';
import '../../../../data/models/daily_model.dart';

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

  // Callback untuk penangan aktivasi/nonaktivasi manual list
  final Function(SubSubjectItem)? onToggleDisable;

  // === CALLBACK BARU UNTUK SEKUENS EXPAND/COLLAPSE TREE ===
  final Function(SubSubjectItem)? onToggleExpansion;

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
    // --- DAFTARKAN PADA CONSTRUCTOR ---
    this.onToggleExpansion,
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

    // Mengecek apakah item ini dikunci oleh relasi kaitan card eksternal (Prasyarat)
    bool isLinkedAndLocked =
        item.linkedSubjectName != null && item.linkedSubjectName!.isNotEmpty;

    // Mengecek apakah item ini menyumbang/mengaitkan akumulasi nilainya ke Card Checklist lain
    bool hasExternalCardLink =
        item.linkedExternalCardName != null &&
        item.linkedExternalItemName != null;

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
              // === ADAPTIF PANAH FOLDING: Tampil jika bukan mode edit & item memiliki turunan sub-materi ===
              if (!isEditMode && item.subMateri.isNotEmpty)
                IconButton(
                  icon: Icon(
                    item.isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(right: 2),
                  onPressed: () => onToggleExpansion?.call(item),
                )
              else if (!isEditMode)
                const SizedBox(
                  width: 22,
                ), // Spacer pengganti ukuran panah agar letak checkbox sejajar semetris

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
                                  item.subjectName +
                                      (isLinkedAndLocked ? ' 🔒' : '') +
                                      (hasExternalCardLink ? ' 🔗' : ''),
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
                          item.isDisabled
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                )
                              : Checkbox(
                                  value: isChecked,
                                  activeColor: item.itemType == 'progress'
                                      ? Colors.deepOrange
                                      : (isLinkedAndLocked
                                            ? Colors.amber[700]
                                            : Colors.teal),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLinkedAndLocked &&
                                        !item.isDisabled) ...[
                                      Tooltip(
                                        message:
                                            'Dikunci kaitan Card: "${item.linkedSubjectName}"',
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 15,
                                          color: isChecked
                                              ? Colors.grey
                                              : Colors.amber[800],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Flexible(
                                      child: Text(
                                        item.subjectName +
                                            (hasExternalCardLink ? ' 🔗' : ''),
                                        style: TextStyle(
                                          fontSize: 14,
                                          // Jika item memiliki anak yang sedang disembunyikan (collapsed), berikan gaya teks miring halus
                                          fontStyle:
                                              !item.isExpanded &&
                                                  item.subMateri.isNotEmpty
                                              ? FontStyle.italic
                                              : (item.isDisabled
                                                    ? FontStyle.italic
                                                    : null),
                                          fontWeight: item.subMateri.isNotEmpty
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          decoration:
                                              item.isDisabled || isChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: item.isDisabled
                                              ? Colors.red.shade300
                                              : (isLinkedAndLocked && !isChecked
                                                    ? Colors.grey.shade700
                                                    : (isChecked
                                                          ? Colors.grey
                                                          : Colors.black87)),
                                        ),
                                      ),
                                    ),
                                    // Berikan badge info jumlah sub-materi jika sedang tertutup
                                    if (!item.isExpanded &&
                                        item.subMateri.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.withOpacity(
                                            0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.subMateri.length}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                // === TOMBOL SHOW MENU (MORE OPTIONS) ===
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onSelected: (String value) {
                    if (value == 'add_child') {
                      onAddChild(item);
                    } else if (value == 'toggle_disable') {
                      onToggleDisable?.call(item);
                    } else if (value == 'toggle_type') {
                      onToggleItemType?.call(item);
                    } else if (value == 'delete') {
                      onDeleteItem(item);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'add_child',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.teal,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Tambah Anak', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggle_disable',
                      child: Row(
                        children: [
                          Icon(
                            item.isDisabled
                                ? Icons.check_circle_outline
                                : Icons.block_flipped,
                            color: item.isDisabled ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.isDisabled
                                ? 'Aktifkan Kembali'
                                : 'Nonaktifkan List',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (item.subMateri.isEmpty && !item.isDisabled)
                      PopupMenuItem<String>(
                        value: 'toggle_type',
                        child: Row(
                          children: [
                            Icon(
                              item.itemType == 'progress'
                                  ? Icons.toggle_on_rounded
                                  : Icons.toggle_off_outlined,
                              color: item.itemType == 'progress'
                                  ? Colors.deepOrange
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.itemType == 'progress'
                                  ? 'Ubah ke Tipe Normal'
                                  : 'Ubah ke Tipe Progress',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hapus Item',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // === SINKRONISASI FILTER EXPAND: Hanya render rekursif anak jika status 'isExpanded' bernilai TRUE atau saat Mode Edit ===
        if (item.subMateri.isNotEmpty && (isEditMode || item.isExpanded))
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
                onToggleDisable: onToggleDisable,
                // --- SUNTIKKAN SAKELAR CALLBACK EXPANSION KE CHILD ---
                onToggleExpansion: onToggleExpansion,
              );
            }),
          ),
      ],
    );
  }
}

extension on String {
  String replaceAllWithRegExp(RegExp regExp, String replacement) {
    return this.replaceAllMapped(regExp, (match) => replacement);
  }
}
