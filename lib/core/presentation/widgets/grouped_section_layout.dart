// lib/core/presentation/widgets/grouped_section_layout.dart
import 'package:flutter/material.dart';
import 'base_detail_app_bar.dart';

class GroupedSectionLayout<T> extends StatefulWidget {
  final String title;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final Widget? emptyStateView;
  final bool isSelectMode;
  final int selectedItemsCount;
  final VoidCallback onClearSelection;
  final bool enableSearch;
  final bool enableMultiSelect;
  final VoidCallback? onMoveMassive;
  final VoidCallback? onDeleteMassive;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAddPressed;
  final Widget? additionalAction;
  final Widget?
  appBarTrailingAction; // <-- PROPERTI BARU: Penampung aksi ikon status enkripsi global
  final List<String> sectionKeys;
  final Map<String, List<T>> groupedItems;
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
  final double childAspectRatio;

  const GroupedSectionLayout({
    super.key,
    required this.title,
    this.drawer,
    this.floatingActionButton,
    required this.isLoading,
    required this.isEmpty,
    this.emptyMessage = 'Belum ada data.',
    this.emptyStateView,
    required this.isSelectMode,
    required this.selectedItemsCount,
    required this.onClearSelection,
    this.enableSearch = true,
    this.enableMultiSelect = true,
    this.onMoveMassive,
    this.onDeleteMassive,
    this.onSearchChanged,
    this.onAddPressed,
    this.additionalAction,
    this.appBarTrailingAction, // <-- MENDAFTARKAN KE KONSTRUKTOR LAYOUT
    required this.sectionKeys,
    required this.groupedItems,
    required this.sectionHeaderBuilder,
    required this.gridItemBuilder,
    this.childAspectRatio = 1.15,
  });

  @override
  State<GroupedSectionLayout<T>> createState() =>
      _GroupedSectionLayoutState<T>();
}

class _GroupedSectionLayoutState<T> extends State<GroupedSectionLayout<T>> {
  bool _internalSearchMode = false;
  bool _internalEditMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAspectRatio = _internalEditMode
        ? 0.95
        : widget.childAspectRatio;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: BaseDetailAppBar(
        pageTitle: widget.title,
        isSelectMode: widget.isSelectMode,
        selectedItemsCount: widget.selectedItemsCount,
        isSearchMode: _internalSearchMode,
        onClearSelection: () {
          setState(() {
            _internalSearchMode = false;
          });
          _searchController.clear();
          if (widget.onSearchChanged != null) widget.onSearchChanged!('');
          widget.onClearSelection();
        },
        onToggleSearchMode: () {
          setState(() {
            _internalSearchMode = !_internalSearchMode;
          });
          if (!_internalSearchMode) {
            _searchController.clear();
            if (widget.onSearchChanged != null) widget.onSearchChanged!('');
          }
        },
        enableSearch: widget.enableSearch,
        enableMultiSelect: widget.enableMultiSelect,
        onMoveMassive: widget.onMoveMassive,
        onDeleteMassive: widget.onDeleteMassive,
        // LOGIKA DINAMIS: Menyisipkan ikon status enkripsi jika panel pencarian sedang ditutup
        additionalAction: _internalSearchMode
            ? widget.additionalAction
            : widget.appBarTrailingAction,
        searchBarContent: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  hintStyle: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onAddPressed,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
      drawer: widget.drawer,
      floatingActionButton: widget.floatingActionButton,
      body: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.isEmpty
          ? (widget.emptyStateView ?? Center(child: Text(widget.emptyMessage)))
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView.builder(
                  itemCount: widget.sectionKeys.length,
                  itemBuilder: (context, index) {
                    final sectionName = widget.sectionKeys[index];
                    final itemsInSection =
                        widget.groupedItems[sectionName] ?? [];
                    if (_internalSearchMode &&
                        itemsInSection.isEmpty &&
                        !sectionName.toLowerCase().contains(
                          _searchController.text.toLowerCase(),
                        )) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.sectionHeaderBuilder(
                          context,
                          index,
                          sectionName,
                          _internalEditMode,
                        ),
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
                  },
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
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
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
