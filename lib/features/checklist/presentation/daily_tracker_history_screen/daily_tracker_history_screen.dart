import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';
import '../../utils/checklist_calculation_helper.dart';
import 'widgets/edit_history_entry_sheet.dart';
import 'widgets/history_bar_chart.dart';
import 'widgets/history_filter_chips.dart';

class DailyTrackerHistoryScreen extends StatefulWidget {
  final DailySubject subject;
  final Future<void> Function()? onDeleteAll;
  final Future<void> Function(String yearMonth)? onDeleteByMonth;
  final Future<void> Function(String dateKey, List<DailyLogEntry> updated)? onEditEntry;
  final Future<void> Function(String dateKey)? onDeleteEntry;

  const DailyTrackerHistoryScreen({
    super.key,
    required this.subject,
    this.onDeleteAll,
    this.onDeleteByMonth,
    this.onEditEntry,
    this.onDeleteEntry,
  });

  @override
  State<DailyTrackerHistoryScreen> createState() =>
      _DailyTrackerHistoryScreenState();
}

class _DailyTrackerHistoryScreenState extends State<DailyTrackerHistoryScreen> {
  HistoryFilterPreset _selectedPreset = HistoryFilterPreset.thisMonth;
  DateTimeRange? _customRange;

  double _countTotal(List<DailyLogEntry> entries) =>
      ChecklistCalculationHelper.countTotalFromLog(entries);

  double _countFinished(List<DailyLogEntry> entries) =>
      ChecklistCalculationHelper.countFinishedFromLog(entries);

  String _formatDisplayDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const monthNames = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        final monthStr =
            (monthNum >= 1 && monthNum <= 12) ? monthNames[monthNum - 1] : parts[1];
        return '$day $monthStr $year';
      }
    } catch (_) {}
    return dateKey;
  }

  /// Memfilter keys dari subject.dailyLogs berdasarkan preset atau custom range
  List<String> get _filteredKeys {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allKeys = widget.subject.dailyLogs.keys.toList();

    return allKeys.where((key) {
      final parsedDate = DateTime.tryParse(key);
      if (parsedDate == null) return false;

      final keyDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      switch (_selectedPreset) {
        case HistoryFilterPreset.thisMonth:
          return keyDate.year == today.year && keyDate.month == today.month;
        case HistoryFilterPreset.last7Days:
          final start7 = today.subtract(const Duration(days: 6));
          return !keyDate.isBefore(start7) && !keyDate.isAfter(today);
        case HistoryFilterPreset.last30Days:
          final start30 = today.subtract(const Duration(days: 29));
          return !keyDate.isBefore(start30) && !keyDate.isAfter(today);
        case HistoryFilterPreset.custom:
          if (_customRange == null) return true;
          final start = DateTime(
            _customRange!.start.year,
            _customRange!.start.month,
            _customRange!.start.day,
          );
          final end = DateTime(
            _customRange!.end.year,
            _customRange!.end.month,
            _customRange!.end.day,
          );
          return !keyDate.isBefore(start) && !keyDate.isAfter(end);
      }
    }).toList();
  }

  void _showDetailSnapshot(String dateKey, List<DailyLogEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.event_note_rounded, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDisplayDate(dateKey),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: _buildRecursiveEntries(entries, 0),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildRecursiveEntries(List<DailyLogEntry> entries, int depth) {
    final List<Widget> widgets = [];
    for (var entry in entries) {
      final isDone = entry.progress == 'selesai';
      final isProgressOrCountdown =
          entry.itemType == 'progress' || entry.itemType == 'countdown';

      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : (entry.progress == 'sementara'
                        ? Icons.timelapse_rounded
                        : Icons.radio_button_unchecked_rounded),
                key: Key(isDone ? 'status_icon_done' : 'status_icon_not_done'),
                color: isDone
                    ? Colors.teal
                    : (entry.progress == 'sementara'
                        ? Colors.amber.shade700
                        : Colors.grey),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.itemName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDone ? Colors.black87 : Colors.grey.shade700,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (isProgressOrCountdown) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${entry.currentValue}/${entry.targetValue})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDone ? Colors.teal : Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      if (entry.children.isNotEmpty) {
        widgets.addAll(_buildRecursiveEntries(entry.children, depth + 1));
      }
    }
    return widgets;
  }

  void _showEntryContextMenu(String dateKey, List<DailyLogEntry> entries) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_calendar_rounded, color: Colors.teal),
                title: const Text('Edit Entry'),
                subtitle: Text(_formatDisplayDate(dateKey)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditSheet(dateKey, entries);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Hapus Entry', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteEntry(dateKey);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditSheet(String dateKey, List<DailyLogEntry> entries) async {
    await EditHistoryEntrySheet.show(
      context: context,
      dateKey: dateKey,
      entries: entries,
      onSave: (updated) async {
        if (widget.onEditEntry != null) {
          await widget.onEditEntry!(dateKey, updated);
        } else {
          widget.subject.dailyLogs[dateKey] = updated;
        }
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _handleDeleteEntry(String dateKey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Entry'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data riwayat tanggal "${_formatDisplayDate(dateKey)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete_entry'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.onDeleteEntry != null) {
        await widget.onDeleteEntry!(dateKey);
      } else {
        widget.subject.dailyLogs.remove(dateKey);
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: Text(
          'Semua riwayat harian untuk "${widget.subject.subjectName}" akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete_all'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.onDeleteAll != null) {
        await widget.onDeleteAll!();
      } else {
        setState(() {
          widget.subject.dailyLogs.clear();
        });
      }
      setState(() {});
    }
  }

  String _formatDisplayMonth(String yearMonth) {
    try {
      final parts = yearMonth.split('-');
      if (parts.length >= 2) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        const monthNames = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        final monthStr =
            (monthNum >= 1 && monthNum <= 12) ? monthNames[monthNum - 1] : parts[1];
        return '$monthStr $year';
      }
    } catch (_) {}
    return yearMonth;
  }

  Future<void> _handleDeleteByMonth() async {
    final months = widget.subject.dailyLogs.keys
        .map((k) => k.length >= 7 ? k.substring(0, 7) : '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (months.isEmpty) return;

    final selectedMonth = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Bulan yang Dihapus'),
        children: months.map((month) {
          return SimpleDialogOption(
            key: Key('month_option_$month'),
            onPressed: () => Navigator.pop(ctx, month),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${_formatDisplayMonth(month)} ($month)',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selectedMonth == null || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Bulan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus seluruh riwayat untuk bulan "${_formatDisplayMonth(selectedMonth)}" ($selectedMonth)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete_month'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.onDeleteByMonth != null) {
        await widget.onDeleteByMonth!(selectedMonth);
      } else {
        setState(() {
          widget.subject.dailyLogs.removeWhere((k, _) => k.startsWith(selectedMonth));
        });
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyData = widget.subject.dailyLogs.isNotEmpty;

    // Keys terfilter
    final filtered = _filteredKeys;
    // Untuk grafik: urutkan ascending
    final chartDateKeys = List<String>.from(filtered)..sort((a, b) => a.compareTo(b));
    // Untuk list: urutkan descending
    final listDateKeys = List<String>.from(filtered)..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.subjectName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (hasAnyData)
            PopupMenuButton<String>(
              key: const Key('btn_history_menu'),
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (val) {
                if (val == 'DELETE_ALL') {
                  _handleDeleteAll();
                } else if (val == 'DELETE_MONTH') {
                  _handleDeleteByMonth();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'DELETE_MONTH',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 20, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hapus per bulan',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'DELETE_ALL',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hapus semua history',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: !hasAnyData
          ? Center(
              key: const Key('daily_tracker_history_empty'),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Riwayat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada data tersimpan. Gunakan tombol \'Simpan Hari Ini\' untuk mulai melacak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HistoryFilterChips(
                        selected: _selectedPreset,
                        customRange: _customRange,
                        onPresetChanged: (preset) {
                          setState(() {
                            _selectedPreset = preset;
                          });
                        },
                        onCustomRangeChanged: (range) {
                          setState(() {
                            _selectedPreset = HistoryFilterPreset.custom;
                            _customRange = range;
                          });
                        },
                      ),
                      HistoryBarChart(
                        dateKeys: chartDateKeys,
                        dailyLogs: widget.subject.dailyLogs,
                        countTotal: _countTotal,
                        countFinished: _countFinished,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (listDateKeys.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Tidak ada entri riwayat pada rentang waktu ini.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final dateKey = listDateKeys[index];
                          final entries = widget.subject.dailyLogs[dateKey] ?? [];
                          final total = _countTotal(entries);
                          final finished = _countFinished(entries);

                          final String finishedText = finished % 1 == 0
                              ? finished.toInt().toString()
                              : finished.toStringAsFixed(1);
                          final String totalText = total % 1 == 0
                              ? total.toInt().toString()
                              : total.toStringAsFixed(1);

                          return Card(
                            key: Key('history_date_tile_$dateKey'),
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _showDetailSnapshot(dateKey, entries),
                              onLongPress: () => _showEntryContextMenu(dateKey, entries),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: finished == total && total > 0
                                          ? Colors.teal.shade50
                                          : Colors.grey.shade100,
                                      child: Icon(
                                        finished == total && total > 0
                                            ? Icons.check_circle_rounded
                                            : Icons.calendar_today_rounded,
                                        color: finished == total && total > 0
                                            ? Colors.teal
                                            : Colors.blueGrey,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDisplayDate(dateKey),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateKey,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: finished == total && total > 0
                                            ? Colors.teal.shade100
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$finishedText / $totalText Selesai',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: finished == total && total > 0
                                              ? Colors.teal.shade800
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: listDateKeys.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
