// lib/core/presentation/widgets/base_detail_app_bar.dart
import 'package:flutter/material.dart';

class BaseDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  final bool isSelectMode;
  final int selectedItemsCount;
  final bool isSearchMode;
  final VoidCallback onClearSelection;
  final VoidCallback onToggleSearchMode;

  // Fitur Flags
  final bool enableSearch;
  final bool enableMultiSelect;

  // Callback Aksi Massal & Global
  final VoidCallback? onMoveMassive;
  final VoidCallback? onDeleteMassive;

  const BaseDetailAppBar({
    super.key,
    required this.pageTitle,
    required this.isSelectMode,
    required this.selectedItemsCount,
    required this.isSearchMode,
    required this.onClearSelection,
    required this.onToggleSearchMode,
    this.enableSearch = true,
    this.enableMultiSelect = true,
    this.onMoveMassive,
    this.onDeleteMassive,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isSelectMode
          ? Colors.yellow[900]
          : const Color(0xFF3F51B5),
      elevation: 0,
      title: Text(
        isSelectMode ? '$selectedItemsCount Terpilih' : pageTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      leading: isSelectMode
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClearSelection,
            )
          : IconButton(
              // Otomatis ganti ikon: jika bisa kembali pakai panah, jika di utama pakai menu
              icon: Icon(
                Navigator.canPop(context) ? Icons.arrow_back : Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Scaffold.of(
                    context,
                  ).openDrawer(); // Membuka drawer dengan ikon menu yang sesuai
                }
              },
            ),
      // flexibleSpace dengan InkWell untuk mendeteksi Long Press di area kosong AppBar
      flexibleSpace: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () {
            if (enableSearch && !isSelectMode) {
              onToggleSearchMode();
            }
          },
          child: const SizedBox.expand(),
        ),
      ),
      actions: [
        if (isSelectMode) ...[
          if (onMoveMassive != null)
            IconButton(
              icon: const Icon(Icons.drive_file_move, color: Colors.white),
              onPressed: onMoveMassive,
            ),
          if (onDeleteMassive != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: onDeleteMassive,
            ),
        ] else if (isSearchMode) ...[
          IconButton(
            icon: const Icon(Icons.search_off_rounded, color: Colors.white),
            onPressed: onToggleSearchMode, // Mematikan search mode
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
