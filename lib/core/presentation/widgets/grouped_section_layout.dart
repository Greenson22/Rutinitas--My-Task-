import 'package:flutter/material.dart';
import 'base_detail_app_bar.dart'; // Impor berkas BaseDetailAppBar

class GroupedSectionLayout<T> extends StatelessWidget {
  final String title;
  final Widget? drawer;
  final Widget? floatingActionButton;

  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;

  // Properti Tambahan untuk BaseDetailAppBar
  final bool isSelectMode;
  final int selectedItemsCount;
  final bool isSearchMode;
  final VoidCallback onClearSelection;
  final VoidCallback onToggleSearchMode;
  final bool enableSearch;
  final bool enableMultiSelect;
  final VoidCallback? onMoveMassive;
  final VoidCallback? onDeleteMassive;

  // Data Map berupa Kategori/Seksi -> List Item
  final List<String> sectionKeys;
  final Map<String, List<T>> groupedItems;

  // Builder untuk menyusun Header & Kotak Grid
  final Widget Function(BuildContext context, int index, String sectionName)
  sectionHeaderBuilder;
  final Widget Function(
    BuildContext context,
    T item,
    int index,
    List<T> sectionItems,
  )
  gridItemBuilder;

  // Proporsi kotak
  final double childAspectRatio;

  const GroupedSectionLayout({
    super.key,
    required this.title,
    this.drawer,
    this.floatingActionButton,
    required this.isLoading,
    required this.isEmpty,
    this.emptyMessage = 'Belum ada data.',
    // Parameter Wajib & Opsional Baru untuk BaseDetailAppBar
    required this.isSelectMode,
    required this.selectedItemsCount,
    required this.isSearchMode,
    required this.onClearSelection,
    required this.onToggleSearchMode,
    this.enableSearch = true,
    this.enableMultiSelect = true,
    this.onMoveMassive,
    this.onDeleteMassive,
    // Parameter Eksisting
    required this.sectionKeys,
    required this.groupedItems,
    required this.sectionHeaderBuilder,
    required this.gridItemBuilder,
    this.childAspectRatio = 1.15,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      // Mengganti AppBar bawaan dengan BaseDetailAppBar
      appBar: BaseDetailAppBar(
        pageTitle: title,
        isSelectMode: isSelectMode,
        selectedItemsCount: selectedItemsCount,
        isSearchMode: isSearchMode,
        onClearSelection: onClearSelection,
        onToggleSearchMode: onToggleSearchMode,
        enableSearch: enableSearch,
        enableMultiSelect: enableMultiSelect,
        onMoveMassive: onMoveMassive,
        onDeleteMassive: onDeleteMassive,
      ),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
          ? Center(child: Text(emptyMessage))
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: sectionKeys.map((sectionName) {
                    final itemsInSection = groupedItems[sectionName] ?? [];
                    final sectionIndex = sectionKeys.indexOf(sectionName);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Render Header Seksi
                        sectionHeaderBuilder(
                          context,
                          sectionIndex,
                          sectionName,
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
                            : _buildResponsiveGrid(itemsInSection, constraints),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  // Logika Responsif bawaan MyChecklistGroup
  Widget _buildResponsiveGrid(List<T> items, BoxConstraints constraints) {
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
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return gridItemBuilder(context, items[index], index, items);
      },
    );
  }
}
