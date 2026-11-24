import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';

class DailyTrackerHistoryScreen extends StatefulWidget {
  final DailySubject subject;
  final Future<void> Function()? onDeleteAll;
  final Future<void> Function(String yearMonth)? onDeleteByMonth;

  const DailyTrackerHistoryScreen({
    super.key,
    required this.subject,
    this.onDeleteAll,
    this.onDeleteByMonth,
  });

  @override
  State<DailyTrackerHistoryScreen> createState() =>
      _DailyTrackerHistoryScreenState();
}

class _DailyTrackerHistoryScreenState extends State<DailyTrackerHistoryScreen> {
  // Menghitung ringkasan item selesai dan total secara rekursif
  int _countTotal(List<DailyLogEntry> entries) {
    int count = 0;
    for (var entry in entries) {
      count++;
      if (entry.children.isNotEmpty) {
        count += _countTotal(entry.children);
      }
    }
    return count;
  }

  int _countFinished(List<DailyLogEntry> entries) {
    int count = 0;
    for (var entry in entries) {
      if (entry.progress == 'selesai') {
        count++;
      }
      if (entry.children.isNotEmpty) {
        count += _countFinished(entry.children);
      }
    }
    return count;
  }

  String _formatDisplayDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final day = parts[2];
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
    // Ambil daftar unique month (yyyy-MM)
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
    // Ambil tanggal terurut descending
    final sortedKeys = widget.subject.dailyLogs.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.subjectName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (sortedKeys.isNotEmpty)
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
      body: sortedKeys.isEmpty
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
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: sortedKeys.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final dateKey = sortedKeys[index];
                final entries = widget.subject.dailyLogs[dateKey] ?? [];
                final total = _countTotal(entries);
                final finished = _countFinished(entries);

                return Card(
                  key: Key('history_date_tile_$dateKey'),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
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
                    title: Text(
                      _formatDisplayDate(dateKey),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: finished == total && total > 0
                            ? Colors.teal.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$finished / $total Selesai',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: finished == total && total > 0
                              ? Colors.teal.shade800
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    onTap: () => _showDetailSnapshot(dateKey, entries),
                  ),
                );
              },
            ),
    );
  }
}
