// lib/features/daily/presentation/widgets/checklist_detail/checklist_dialog/checklist_tree_view.dart

import 'package:flutter/material.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/documents/data/services/document_file_service.dart';
import 'package:rutinitasku/features/multimedia/services/multimedia_opener_service.dart';
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

  // Callback untuk kustomisasi Progress angka harian (Menerima parameter string tipe)
  final Function(SubSubjectItem, String)? onToggleItemType;
  final Function(SubSubjectItem)? onUpdateProgressValue;

  // Callback untuk penangan aktivasi/nonaktivasi manual list
  final Function(SubSubjectItem)? onToggleDisable;

  // Callback untuk sekuens expand/collapse tree
  final Function(SubSubjectItem)? onToggleExpansion;

  // Callback opsional untuk meresolve teks akumulasi eksternal (contoh: "(45/100)")
  final String? Function(SubSubjectItem)? resolveExternalAccumulationText;

  // Callback opsional untuk meresolve persentase penyelesaian Card prasyarat (0-100)
  final int? Function(SubSubjectItem)? resolvePrerequisitePercentage;

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
    this.onToggleExpansion,
    this.resolveExternalAccumulationText,
    this.resolvePrerequisitePercentage,
  });

  // Fungsi pembantu untuk memformat angka dengan separator titik ribuan Indonesia
  String _formatNumber(int number) {
    return number.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
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
        (item.linkedExternalItemId != null || item.linkedExternalItemName != null);

    final String? externalAccumulationText =
        hasExternalCardLink && resolveExternalAccumulationText != null
            ? resolveExternalAccumulationText!(item)
            : null;

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

              // ====================================================
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
                                )
                              else if (item.itemType == 'countdown')
                                const Icon(
                                  Icons.exposure_minus_1_rounded,
                                  size: 16,
                                  color: Colors.deepOrange,
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: item.hasLinkedDocument ? '📎 ${item.subjectName}' : item.subjectName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily:
                                          'Roboto', // Memastikan fallback font aman
                                      color: item.isDisabled
                                          ? Colors.red.shade400
                                          : (item.textColor != null
                                                ? Color(item.textColor!)
                                                : Colors.black87),
                                      decoration: item.isDisabled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    children: [
                                      if (isLinkedAndLocked)
                                        const WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 4.0),
                                            child: Icon(
                                              Icons.lock_outline,
                                              size: 14,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                      if (hasExternalCardLink)
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 4.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.bolt,
                                                  size: 15,
                                                  color: Colors.amber,
                                                ),
                                                if (externalAccumulationText != null &&
                                                    externalAccumulationText.isNotEmpty) ...[
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    externalAccumulationText,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.indigo,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      // MENAMPILKAN TANGGAL SELESAI DI MODE EDIT BERBASIS TEXTSPAN
                                      if (isChecked &&
                                          item.finishedDate != null &&
                                          item.finishedDate!.isNotEmpty)
                                        TextSpan(
                                          text: ' (${item.finishedDate})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.green.shade700,
                                            decoration: TextDecoration
                                                .none, // Supaya tanggal tidak ikut tercoret
                                          ),
                                        ),
                                    ],
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
                                  activeColor:
                                      (item.itemType == 'progress' ||
                                          item.itemType == 'countdown')
                                      ? Colors.deepOrange
                                      : (isLinkedAndLocked
                                            ? Colors.amber[700]
                                            : Colors.teal),
                                  onChanged:
                                      (item.itemType == 'progress' ||
                                          item.itemType == 'countdown')
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
                                      if (item.itemType == 'progress' ||
                                          item.itemType == 'countdown') {
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
                                      child: RichText(
                                        text: TextSpan(
                                          text: item.hasLinkedDocument ? '📎 ${item.subjectName}' : item.subjectName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Roboto',
                                            fontStyle:
                                                !item.isExpanded &&
                                                    item.subMateri.isNotEmpty
                                                ? FontStyle.italic
                                                : (item.isDisabled
                                                      ? FontStyle.italic
                                                      : null),
                                            fontWeight:
                                                item.subMateri.isNotEmpty
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            decoration:
                                                item.isDisabled || isChecked
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: item.isDisabled
                                                ? Colors.red.shade300
                                                : (isLinkedAndLocked &&
                                                          !isChecked
                                                      ? Colors.grey.shade700
                                                      : (isChecked
                                                            ? Colors.grey
                                                            : (item.textColor !=
                                                                      null
                                                                  ? Color(
                                                                      item.textColor!,
                                                                    )
                                                                  : Colors
                                                                        .black87))),
                                          ),
                                          children: [
                                            if (isLinkedAndLocked &&
                                                resolvePrerequisitePercentage
                                                        ?.call(item) !=
                                                    null)
                                              TextSpan(
                                                text:
                                                    ' (${resolvePrerequisitePercentage!.call(item)}%)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.amber[800],
                                                ),
                                              ),
                                            if (hasExternalCardLink)
                                              WidgetSpan(
                                                alignment:
                                                    PlaceholderAlignment.middle,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 4.0,
                                                      ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.bolt,
                                                        size: 15,
                                                        color: isChecked
                                                            ? Colors.grey
                                                            : Colors.amber[700],
                                                      ),
                                                      if (externalAccumulationText != null &&
                                                          externalAccumulationText.isNotEmpty) ...[
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          externalAccumulationText,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: isChecked
                                                                ? Colors.grey
                                                                : Colors.indigo.shade700,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            // MENAMPILKAN TANGGAL SELESAI DI MODE NORMAL/PRATINJAU BERBASIS TEXTSPAN
                                            if (isChecked &&
                                                item.finishedDate != null &&
                                                item.finishedDate!.isNotEmpty)
                                              TextSpan(
                                                text: ' (${item.finishedDate})',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.green.shade600,
                                                  decoration: TextDecoration
                                                      .none, // Supaya tanggal tidak ikut tercoret
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
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
                          if ((item.itemType == 'progress' ||
                                  item.itemType == 'countdown') &&
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
                                  item.itemType == 'countdown'
                                      ? Icons.remove_circle_outline_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 14,
                                  color: isChecked
                                      ? Colors.grey
                                      : Colors.deepOrange,
                                ),
                                label: Text(
                                  item.itemType == 'countdown'
                                      ? _formatNumber(item.currentValue)
                                      : '${_formatNumber(item.currentValue)} / ${_formatNumber(item.targetValue)}',
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
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onSelected: (String value) async {
                    if (value == 'open_linked_file') {
                      final baseDir = await StorageService().getBaseDirSetting();
                      final file = DocumentFileService(baseDir: baseDir)
                          .resolveRelativePath(
                            item.linkedDocumentGroupId!,
                            item.linkedDocumentRelativePath!,
                          );
                      if (await file.exists()) {
                        if (context.mounted) {
                          await MultimediaOpenerService.openFile(context, file);
                        }
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Berkas tidak ditemukan'),
                            action: SnackBarAction(
                              label: 'Lepas',
                              onPressed: () {
                                item.linkedDocumentGroupId = null;
                                item.linkedDocumentRelativePath = null;
                                item.linkedDocumentName = null;
                              },
                            ),
                          ),
                        );
                      }
                    } else if (value == 'add_child') {
                      onAddChild(item);
                    } else if (value == 'toggle_disable') {
                      onToggleDisable?.call(item);
                    } else if (value.startsWith('type_')) {
                      onToggleItemType?.call(
                        item,
                        value.replaceFirst('type_', ''),
                      );
                    } else if (value == 'delete') {
                      onDeleteItem(item);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    if (item.hasLinkedDocument)
                      const PopupMenuItem<String>(
                        value: 'open_linked_file',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 18, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text('Buka Berkas'),
                          ],
                        ),
                      ),
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

                    // =========================================================
                    // OPSIONAL RUANG KONFIGURASI TIPE DI BAWAH UBAH TIPE PROGRESS
                    // =========================================================
                    if (item.subMateri.isEmpty && !item.isDisabled) ...[
                      if (item.itemType != 'normal')
                        PopupMenuItem<String>(
                          value: 'type_normal',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.toggle_off_outlined,
                                color: Colors.grey,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ubah ke Tipe Normal',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      if (item.itemType != 'progress')
                        PopupMenuItem<String>(
                          value: 'type_progress',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.toggle_on_rounded,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ubah ke Tipe Progress',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      if (item.itemType != 'countdown')
                        PopupMenuItem<String>(
                          value: 'type_countdown',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.exposure_minus_1_rounded,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ubah ke Tipe Hitung Mundur',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                    ],
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
              if (!isEditMode && item.subMateri.isNotEmpty)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: Icon(
                      item.isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: Colors.blueGrey,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => onToggleExpansion?.call(item),
                  ),
                ),
            ],
          ),
        ),
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
                onToggleExpansion: onToggleExpansion,
                resolveExternalAccumulationText:
                    resolveExternalAccumulationText,
                resolvePrerequisitePercentage: resolvePrerequisitePercentage,
              );
            }),
          ),
      ],
    );
  }
}
