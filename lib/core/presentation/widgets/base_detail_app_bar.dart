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

  // Konten isi kolom pencarian yang disuntikkan dari parent screen
  final Widget? searchBarContent;

  // TAMBAHAN BARU: Widget aksi tambahan di sisi kanan title atau menu (opsional)
  final Widget? additionalAction;

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
    this.searchBarContent,
    this.additionalAction, // <--- Daftarkan di konstruktor
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
              icon: Icon(
                Navigator.canPop(context) ? Icons.arrow_back : Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            ),
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
        ] else ...[
          // TAMBAHAN BARU: Munculkan tombol aksi kustom jika dikirim dari parent
          if (additionalAction != null) additionalAction!,

          if (isSearchMode)
            IconButton(
              icon: const Icon(Icons.search_off_rounded, color: Colors.white),
              onPressed: onToggleSearchMode,
            ),
        ],
      ],
      bottom: isSearchMode
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70.0),
              child: ClipRect(
                child: Container(
                  height: 70.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: SizedOverflowBox(
                    size: const Size.fromHeight(54.0),
                    alignment: Alignment.topCenter,
                    child: searchBarContent ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (isSearchMode ? 70.0 : 0.0));
}
