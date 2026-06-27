// lib/core/presentation/widgets/base_detail_list_screen.dart
import 'package:flutter/material.dart';
import 'base_detail_app_bar.dart';

class BaseDetailListScreen<T> extends StatefulWidget {
  final String pageTitle;
  final List<T> items;

  final bool enableSearch;
  final bool enableMultiSelect;
  final bool enableAddButton;
  final bool enableFavoriteSort;

  final String Function(T item) itemTitle;
  final Widget Function(T item) itemSubtitle;
  final String Function(T item)? itemSearchString;
  final bool Function(T item) itemIsFavorite;

  final Widget? additionalAction; // Digunakan saat mode normal (misal: Sorting)

  final VoidCallback? onAddPressed;
  final Function(T item)? onItemTap;
  final Function(T item)? onItemLongPress;
  final Function(List<T> selectedItems)? onDeleteMassive;
  final Function(List<T> selectedItems)? onMoveMassive;

  // -------------------------------------------------------------------------
  // PENINGKATAN: PARAMETER AKSI MASAL DUKUNGAN EKSPOR DAN BAGIKAN GENERIC
  // -------------------------------------------------------------------------
  final Function(List<T> selectedItems)? onExportMassive;
  final Function(List<T> selectedItems)? onShareMassive; // <-- TAMBAHAN BARU

  final List<PopupMenuEntry<String>> Function(T item)? itemMenuBuilder;
  final Function(String value, T item)? onItemMenuSelected;

  const BaseDetailListScreen({
    super.key,
    required this.pageTitle,
    required this.items,
    this.enableSearch = true,
    this.enableMultiSelect = true,
    this.enableAddButton = true,
    this.enableFavoriteSort = true,
    required this.itemTitle,
    required this.itemSubtitle,
    this.itemSearchString,
    required this.itemIsFavorite,
    this.onAddPressed,
    this.onItemTap,
    this.onItemLongPress,
    this.onDeleteMassive,
    this.onMoveMassive,
    this.onExportMassive,
    this.onShareMassive, // Inisialisasi parameter baru ke konstruktor
    this.itemMenuBuilder,
    this.onItemMenuSelected,
    this.additionalAction,
  });

  @override
  State<BaseDetailListScreen<T>> createState() =>
      _BaseDetailListScreenState<T>();
}

class _BaseDetailListScreenState<T> extends State<BaseDetailListScreen<T>> {
  bool _isSearchMode = false;
  bool _isSelectMode = false;
  final List<T> _selectedItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelect(T item) {
    if (!widget.enableMultiSelect) return;
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
      _isSelectMode = _selectedItems.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
      _isSelectMode = false;
    });
  }

  void _handleToggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<T> filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final title = widget.itemTitle(item).toLowerCase();
      final subtitle = widget.itemSearchString != null
          ? widget.itemSearchString!(item).toLowerCase()
          : '';
      return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
    }).toList();

    if (widget.enableFavoriteSort) {
      filteredItems.sort((a, b) {
        final aFav = widget.itemIsFavorite(a);
        final bFav = widget.itemIsFavorite(b);
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;
        return 0;
      });
    }

    // =========================================================================
    // LOGIKA DINAMIS: SELEKSI MENU BERDASARKAN MODE EDIT MASAL
    // =========================================================================
    Widget? activeAppBarAction = widget.additionalAction;

    if (_isSelectMode) {
      activeAppBarAction = PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
        tooltip: 'Aksi Masal',
        onSelected: (value) async {
          final selectedCopy = List<T>.from(_selectedItems);
          if (value == 'move_massive' && widget.onMoveMassive != null) {
            widget.onMoveMassive!(selectedCopy);
            _clearSelection();
          } else if (value == 'export_massive' &&
              widget.onExportMassive != null) {
            await widget.onExportMassive!(selectedCopy);
            _clearSelection();
          } else if (value == 'share_massive' &&
              widget.onShareMassive != null) {
            await widget.onShareMassive!(selectedCopy);
            _clearSelection();
          } else if (value == 'delete_massive' &&
              widget.onDeleteMassive != null) {
            await widget.onDeleteMassive!(selectedCopy);
            _clearSelection();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            enabled: false,
            child: Text(
              'Aksi Pilihan Masal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          if (widget.onMoveMassive != null)
            const PopupMenuItem(
              value: 'move_massive',
              child: Row(
                children: [
                  Icon(
                    Icons.drive_file_move_outlined,
                    size: 18,
                    color: Colors.indigo,
                  ),
                  SizedBox(width: 10),
                  Text('Pindahkan Masal', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          if (widget.onExportMassive != null)
            const PopupMenuItem(
              value: 'export_massive',
              child: Row(
                children: [
                  Icon(Icons.output_rounded, size: 18, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('Ekspor Masal', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          if (widget.onShareMassive != null)
            const PopupMenuItem(
              value: 'share_massive',
              child: Row(
                children: [
                  Icon(Icons.share_rounded, size: 18, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Bagikan Masal', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          if (widget.onDeleteMassive != null) ...[
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete_massive',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text(
                    'Hapus Masal',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: BaseDetailAppBar(
        pageTitle: widget.pageTitle,
        isSelectMode: _isSelectMode,
        selectedItemsCount: _selectedItems.length,
        isSearchMode: _isSearchMode,
        enableSearch: widget.enableSearch,
        enableMultiSelect: widget.enableMultiSelect,
        onClearSelection: _clearSelection,
        onToggleSearchMode: _handleToggleSearch,
        additionalAction: activeAppBarAction,
        searchBarContent: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
            if (widget.enableAddButton && widget.onAddPressed != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onAddPressed,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = _selectedItems.contains(item);

                      return Card(
                        elevation: isSelected ? 4 : 0,
                        color: isSelected
                            ? Colors.yellow.withOpacity(0.08)
                            : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.yellow[700]!
                                : Colors.grey.shade100,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (_isSelectMode) {
                              _toggleSelect(item);
                            } else {
                              if (widget.onItemTap != null)
                                widget.onItemTap!(item);
                            }
                          },
                          onLongPress: () {
                            if (widget.onItemLongPress != null) {
                              widget.onItemLongPress!(item);
                            } else {
                              _toggleSelect(item);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                if (_isSelectMode) ...[
                                  Checkbox(
                                    activeColor: Colors.yellow[700],
                                    value: isSelected,
                                    onChanged: (_) => _toggleSelect(item),
                                  ),
                                  const SizedBox(width: 12),
                                ] else ...[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8EAF6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.description_rounded,
                                      color: Color(0xFF3F51B5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              widget.itemTitle(item),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF2E3A59),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (widget.itemIsFavorite(item)) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      widget.itemSubtitle(item),
                                    ],
                                  ),
                                ),
                                if (_isSelectMode &&
                                    _selectedItems.length <= 1 &&
                                    widget.itemMenuBuilder != null) ...[
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      color: Colors.black38,
                                    ),
                                    onSelected: (val) {
                                      if (widget.onItemMenuSelected != null) {
                                        widget.onItemMenuSelected!(val, item);
                                      }
                                    },
                                    itemBuilder: (ctx) =>
                                        widget.itemMenuBuilder!(item),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
