import 'package:flutter/material.dart';

class BaseDetailListScreen<T> extends StatefulWidget {
  final String pageTitle;
  final List<T> items;

  // Fitur Flags (Bisa diaktifkan / dinonaktifkan)
  final bool enableSearch;
  final bool enableMultiSelect;
  final bool enableAddButton;
  final bool enableFavoriteSort;

  // Pemetaan Data (Agar Fleksibel untuk Model Apapun)
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;
  final bool Function(T item) itemIsFavorite;

  // Callback Aksi
  final VoidCallback? onAddPressed;
  final Function(T item)? onItemTap;
  final Function(T item)? onItemLongPress;
  final Function(List<T> selectedItems)? onDeleteMassive;
  final Function(List<T> selectedItems)? onMoveMassive;
  final List<PopupMenuEntry<String>> Function(T item)? itemMenuBuilder;
  final Function(String value, T item)? onItemMenuSelected;

  const BaseDetailListScreen({
    super.key,
    required this.pageTitle,
    required this.items,
    this.enableSearch = true, // Default aktif
    this.enableMultiSelect = true, // Default aktif
    this.enableAddButton = true, // Default aktif
    this.enableFavoriteSort = true, // Default aktif
    required this.itemTitle,
    required this.itemSubtitle,
    required this.itemIsFavorite,
    this.onAddPressed,
    this.onItemTap,
    this.onItemLongPress,
    this.onDeleteMassive,
    this.onMoveMassive,
    this.itemMenuBuilder,
    this.onItemMenuSelected,
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

  @override
  Widget build(BuildContext context) {
    // 1. LOGIKA FILTERING
    List<T> filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final title = widget.itemTitle(item).toLowerCase();
      final subtitle = widget.itemSubtitle(item).toLowerCase();
      return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
    }).toList();

    // 2. LOGIKA SORTING FAVORITE
    if (widget.enableFavoriteSort) {
      filteredItems.sort((a, b) {
        final aFav = widget.itemIsFavorite(a);
        final bFav = widget.itemIsFavorite(b);
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;
        return 0;
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _isSelectMode
            ? Colors.red[900]
            : const Color(0xFF3F51B5),
        elevation: 0,
        // 1. Teks title dibuat statis tanpa inkwell internal agar tidak tabrakan gesture
        title: Text(
          _isSelectMode
              ? '${_selectedItems.length} Terpilih'
              : widget.pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: _isSelectMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearSelection,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        // 2. Gunakan flexibleSpace untuk memasang InkWell seluas seluruh dimensi AppBar
        flexibleSpace: Material(
          color:
              Colors.transparent, // Supaya warna AppBar di atas tetap terlihat
          child: InkWell(
            onLongPress: () {
              if (widget.enableSearch && !_isSelectMode) {
                setState(() {
                  _isSearchMode = !_isSearchMode;
                  if (!_isSearchMode) _searchController.clear();
                });
              }
            },
            child:
                const SizedBox.expand(), // Memaksa InkWell memenuhi seluruh area AppBar
          ),
        ),
        actions: [
          if (_isSelectMode) ...[
            if (widget.onMoveMassive != null)
              IconButton(
                icon: const Icon(Icons.drive_file_move, color: Colors.white),
                onPressed: () => widget.onMoveMassive!(_selectedItems),
              ),
            if (widget.onDeleteMassive != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  widget.onDeleteMassive!(_selectedItems);
                  _clearSelection();
                },
              ),
          ] else if (_isSearchMode) ...[
            IconButton(
              icon: const Icon(Icons.search_off_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearchMode = false;
                  _searchController.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ANIMATED SEARCH BAR
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _isSearchMode ? 70.0 : 0.0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF3F51B5),
            clipBehavior: Clip.antiAlias,
            child: _isSearchMode
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari...',
                            hintStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (widget.enableAddButton &&
                          widget.onAddPressed != null) ...[
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
                  )
                : const SizedBox.shrink(),
          ),

          // LIST VIEW
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
                            ? Colors.red.withOpacity(0.08)
                            : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.red[700]!
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
                                    activeColor: Colors.red[700],
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
                                      Text(
                                        widget.itemSubtitle(item),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ACTION POPUP MENU INDIVIDU
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
