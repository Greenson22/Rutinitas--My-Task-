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

  // Widget aksi tambahan di sisi kanan title atau menu (opsional)
  final Widget? additionalAction;

  // TAMBAHAN BARU: Kunci agar selalu memunculkan tombol menu/drawer (garis tiga)
  final bool forceShowMenu;

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
    this.additionalAction,
    this.forceShowMenu =
        false, // Beri nilai default false agar tidak merusak halaman lain
  });

  @override
  Widget build(BuildContext context) {
    // Cek apakah rute saat ini bisa melakukan pop dan tidak dipaksa menampilkan menu
    final bool canPop = Navigator.canPop(context) && !forceShowMenu;

    return AppBar(
      backgroundColor: isSelectMode
          ? Colors.yellow[900]
          : const Color(0xFF3F51B5),
      elevation: 2,
      leading: isSelectMode
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClearSelection,
            )
          : IconButton(
              icon: Icon(
                canPop ? Icons.arrow_back : Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            ),
      title: isSelectMode
          ? Text(
              '$selectedItemsCount Terpilih',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          : Text(
              pageTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: [
        if (enableSearch && !isSelectMode)
          IconButton(
            onPressed: onToggleSearchMode,
            // --- MODIFIKASI: Mengubah Ikon Buka/Tutup & Efek Animasi ---
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) {
                // 1. Buat drive animasi untuk rotasi dengan kurva easeInOut
                final Animation<double> rotationAnimation = animation.drive(
                  Tween<double>(
                    begin: child.key == const ValueKey('icon_open_panel')
                        ? -0.5
                        : 0.5,
                    end: 0.0,
                  ).chain(CurveTween(curve: Curves.easeInOut)),
                );

                // 2. Buat drive animasi untuk scale dengan kurva easeInOut
                final Animation<double> scaleAnimation = animation.drive(
                  Tween<double>(
                    begin: 0.8,
                    end: 1.0,
                  ).chain(CurveTween(curve: Curves.easeInOut)),
                );

                // 3. Gabungkan semua transisinya
                return RotationTransition(
                  turns: rotationAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: scaleAnimation, child: child),
                  ),
                );
              },
              child: isSearchMode
                  ? const Icon(
                      Icons
                          .keyboard_arrow_up_rounded, // Panah ke ATAS saat panel terbuka (klik untuk collapse)
                      color: Colors.white,
                      size: 26,
                      key: ValueKey('icon_close_panel'),
                    )
                  : const Icon(
                      Icons
                          .keyboard_arrow_down_rounded, // Panah ke BAWAH saat panel tertutup (klik untuk expand menu/search)
                      color: Colors.white,
                      size: 26,
                      key: ValueKey('icon_open_panel'),
                    ),
            ),
            tooltip: isSearchMode
                ? 'Sembunyikan Panel'
                : 'Tampilkan Menu & Pencarian',
          ),
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
          if (additionalAction != null) additionalAction!,
          // Tombol bawaan search_off_rounded di bawah ini dihapus / disesuaikan agar tidak double icon panah
          if (isSearchMode)
            IconButton(
              icon: const Icon(Icons.unfold_less_rounded, color: Colors.white),
              onPressed: onToggleSearchMode,
              tooltip: 'Collapse',
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
