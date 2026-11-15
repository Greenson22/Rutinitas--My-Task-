import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/operations/task_search.dart';

/// Kolom pencarian dan filter tugas yang dipakai dashboard dan detail
/// kategori.
///
/// Input ditunda selama [taskSearchDebounce] agar daftar tidak disaring ulang
/// pada setiap karakter. Nilai [query] tetap menjadi sumber kebenaran dari
/// controller; widget ini hanya menjaga isi kolom teks tetap sinkron.
class TaskSearchToolbar extends StatefulWidget {
  const TaskSearchToolbar({
    super.key,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
    this.hintText = 'Cari kategori atau tugas',
  });

  final String query;
  final TaskFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TaskFilter> onFilterChanged;
  final String hintText;

  @override
  State<TaskSearchToolbar> createState() => _TaskSearchToolbarState();
}

class _TaskSearchToolbarState extends State<TaskSearchToolbar> {
  late final TextEditingController _textController;
  Timer? _debounce;

  /// Query terakhir yang diketahui berasal dari luar widget ini.
  late String _syncedQuery;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.query);
    _syncedQuery = widget.query;
  }

  @override
  void didUpdateWidget(covariant TaskSearchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == _syncedQuery) return;

    // Query berubah dari luar (misalnya aksi "hapus pencarian/filter").
    // Hanya saat itu isi kolom teks perlu dipaksa sinkron, sehingga ketikan
    // yang masih menunggu debounce tidak terhapus oleh rebuild lain.
    _syncedQuery = widget.query;
    _debounce?.cancel();
    if (_textController.text != widget.query) {
      _textController.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _handleQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(taskSearchDebounce, () {
      _debounce = null;
      final normalized = value.trim();
      _syncedQuery = normalized;
      widget.onQueryChanged(normalized);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _debounce = null;
    _textController.clear();
    _syncedQuery = '';
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _textController,
          builder: (context, value, _) {
            return TextField(
              key: const Key('taskSearchField'),
              controller: _textController,
              onChanged: _handleQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('taskSearchClearButton'),
                        tooltip: 'Hapus pencarian',
                        onPressed: _clearQuery,
                        icon: const Icon(Icons.close_rounded),
                      ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final filter in TaskFilter.values)
              ChoiceChip(
                key: Key('taskFilter_${filter.name}'),
                label: Text(taskFilterLabel(filter)),
                selected: widget.filter == filter,
                onSelected: (_) => widget.onFilterChanged(filter),
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.filter == filter
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
