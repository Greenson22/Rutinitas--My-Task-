import 'package:flutter/material.dart';
import 'base_detail_app_bar.dart'; // Impor berkas BaseDetailAppBar

class GroupedSectionLayout<T> extends StatefulWidget {
  final String title;
  final Widget? drawer;
  final Widget? floatingActionButton;

  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;

  // Properti Multi-Select eksternal tetap dipertahankan jika dibutuhkan oleh screen induk
  final bool isSelectMode;
  final int selectedItemsCount;
  final VoidCallback onClearSelection;
  final bool enableSearch;
  final bool enableMultiSelect;
  final VoidCallback? onMoveMassive;
  final VoidCallback? onDeleteMassive;

  // Data Map berupa Kategori/Seksi -> List Item
  final List<String> sectionKeys;
  final Map<String, List<T>> groupedItems;

  // Builder untuk menyusun Header & Kotak Grid
  // MODIFIKASI: Menambahkan parameter `isPageEditMode` ke builder agar seksi & card tahu kapan harus merubah mode add/edit
  final Widget Function(
    BuildContext context,
    int index,
    String sectionName,
    bool isPageEditMode,
  )
  sectionHeaderBuilder;
  final Widget Function(
    BuildContext context,
    T item,
    int index,
    List<T> sectionItems,
    bool isPageEditMode,
  )
  gridItemBuilder;

  // Proporsi kotak default saat normal
  final double childAspectRatio;

  const GroupedSectionLayout({
    super.key,
    required this.title,
    this.drawer,
    this.floatingActionButton,
    required this.isLoading,
    required this.isEmpty,
    this.emptyMessage = 'Belum ada data.',
    required this.isSelectMode,
    required this.selectedItemsCount,
    required this.onClearSelection,
    this.enableSearch = true,
    this.enableMultiSelect = true,
    this.onMoveMassive,
    this.onDeleteMassive,
    required this.sectionKeys,
    required this.groupedItems,
    required this.sectionHeaderBuilder,
    required this.gridItemBuilder,
    this.childAspectRatio = 1.15,
    // Parameter isSearchMode & onToggleSearchMode dihapus dari konstruktor karena dikelola internal
  });

  @override
  State<GroupedSectionLayout<T>> createState() =>
      _GroupedSectionLayoutState<T>();
}

class _GroupedSectionLayoutState<T> extends State<GroupedSectionLayout<T>> {
  // Manajemen state internal untuk Search dan Mode Edit/Add kartu
  bool _internalSearchMode = false;
  bool _internalEditMode = false;

  @override
  Widget build(BuildContext context) {
    // Penyesuaian aspek rasio otomatis: jika mode edit aktif maka kotak memanjang kebawah (0.95), jika normal pakai default
    final currentAspectRatio = _internalEditMode
        ? 0.95
        : widget.childAspectRatio;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: BaseDetailAppBar(
        pageTitle: widget.title,
        isSelectMode: widget.isSelectMode,
        selectedItemsCount: widget.selectedItemsCount,
        isSearchMode: _internalSearchMode, // Menggunakan state internal
        onClearSelection: () {
          setState(() {
            _internalSearchMode = false;
          });
          widget.onClearSelection();
        },
        onToggleSearchMode: () {
          // Trigger utama: Saat ditahan, balikkan status search bar dan edit/add mode secara simultan
          setState(() {
            _internalSearchMode = !_internalSearchMode;
            _internalEditMode = !_internalEditMode;
          });
        },
        enableSearch: widget.enableSearch,
        enableMultiSelect: widget.enableMultiSelect,
        onMoveMassive: widget.onMoveMassive,
        onDeleteMassive: widget.onDeleteMassive,
      ),
      drawer: widget.drawer,
      floatingActionButton: widget.floatingActionButton,
      body: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.isEmpty
          ? Center(child: Text(widget.emptyMessage))
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: widget.sectionKeys.map((sectionName) {
                    final itemsInSection =
                        widget.groupedItems[sectionName] ?? [];
                    final sectionIndex = widget.sectionKeys.indexOf(
                      sectionName,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Render Header Seksi (Menyuntikkan state _internalEditMode)
                        widget.sectionHeaderBuilder(
                          context,
                          sectionIndex,
                          sectionName,
                          _internalEditMode,
                        ),

                        // 2. Render Grid / Pesan Kosong
                        itemsInSection.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(
                                  left: 24,
                                  top: 12,
                                  bottom: 12,
                                ),
                                child: Text(
                                  'Belum ada item di seksi ini.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : _buildResponsiveGrid(
                                itemsInSection,
                                constraints,
                                currentAspectRatio,
                              ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildResponsiveGrid(
    List<T> items,
    BoxConstraints constraints,
    double aspectRatio,
  ) {
    int crossAxisCount = 2;
    if (constraints.maxWidth >= 1200) {
      crossAxisCount = 5;
    } else if (constraints.maxWidth >= 900) {
      crossAxisCount = 4;
    } else if (constraints.maxWidth >= 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio, // Menggunakan rasio aspek dinamis
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        // Menyuntikkan state _internalEditMode langsung ke grid item builder
        return widget.gridItemBuilder(
          context,
          items[index],
          index,
          items,
          _internalEditMode,
        );
      },
    );
  }
}
