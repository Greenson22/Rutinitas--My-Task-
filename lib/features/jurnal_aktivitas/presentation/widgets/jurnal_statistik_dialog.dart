// lib/features/jurnal_aktivitas/presentation/widgets/jurnal_statistik_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/time_log_model.dart';

class JurnalStatistikDialog extends StatefulWidget {
  final List<TimeLogEntry> logs;

  const JurnalStatistikDialog({super.key, required this.logs});

  @override
  State<JurnalStatistikDialog> createState() => _JurnalStatistikDialogState();
}

class _JurnalStatistikDialogState extends State<JurnalStatistikDialog> {
  String _selectedFilter = 'Minggu Ini';
  final List<String> _filters = [
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
    'Semua Waktu',
    'Pilih Rentang',
  ];

  DateTimeRange? _customRange;

  // Palet warna untuk grafik batang (berulang jika data lebih banyak)
  final List<Color> _barColors = [
    Colors.teal,
    Colors.indigo,
    Colors.amber.shade700,
    Colors.pink.shade600,
    Colors.purple.shade600,
    Colors.orange.shade700,
    Colors.cyan.shade700,
    Colors.redAccent,
  ];

  // Helper untuk membersihkan jam/menit agar perbandingan tanggal akurat
  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isDateInRange(DateTime date) {
    final now = _stripTime(DateTime.now());
    final target = _stripTime(date);

    switch (_selectedFilter) {
      case 'Minggu Ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return target.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            target.isBefore(endOfWeek.add(const Duration(days: 1)));
      case 'Bulan Ini':
        return target.year == now.year && target.month == now.month;
      case 'Tahun Ini':
        return target.year == now.year;
      case 'Pilih Rentang':
        if (_customRange == null) return true;
        final start = _stripTime(_customRange!.start);
        final end = _stripTime(_customRange!.end);
        return target.isAfter(start.subtract(const Duration(days: 1))) &&
            target.isBefore(end.add(const Duration(days: 1)));
      case 'Semua Waktu':
      default:
        return true;
    }
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _customRange ??
          DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedFilter = 'Pilih Rentang';
      });
    }
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0 mnt';
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h > 0 && m > 0) return '${h}j ${m}m';
    if (h > 0) return '${h}j';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Kumpulkan dan filter data
    Map<String, int> taskDurations = {};
    int totalMinutesAll = 0;

    for (var entry in widget.logs) {
      try {
        DateTime date = DateTime.parse(entry.tanggal);
        if (_isDateInRange(date)) {
          for (var task in entry.tasks) {
            if (task.durasiMenit > 0) {
              taskDurations[task.nama] =
                  (taskDurations[task.nama] ?? 0) + task.durasiMenit;
              totalMinutesAll += task.durasiMenit;
            }
          }
        }
      } catch (_) {}
    }

    // 2. Urutkan berdasarkan durasi terlama
    var sortedEntries = taskDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int maxMinutes = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // === HEADER ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.indigo[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Statistik Aktivitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // === FILTER & KONTROL ===
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedFilter,
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.indigo,
                        ),
                        items: _filters.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val == 'Pilih Rentang') {
                            _selectCustomRange();
                          } else if (val != null) {
                            setState(() {
                              _selectedFilter = val;
                              _customRange = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedFilter == 'Pilih Rentang' && _customRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Rentang: ${DateFormat('dd MMM yyyy').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customRange!.end)}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _selectCustomRange,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text('Ubah'),
                  ),
                ],
              ),
            ),

          // === OVERVIEW TOTAL DURASI ===
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[600]!, Colors.teal[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Waktu Dihabiskan',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        _formatDuration(totalMinutesAll),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 24),

          // === GRAFIK & LIST AKTIVITAS ===
          Expanded(
            child: sortedEntries.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada aktivitas di periode ini.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final item = sortedEntries[index];
                      final double percentage = item.value / maxMinutes;
                      final double percentageTotal =
                          item.value / totalMinutesAll;
                      final Color barColor =
                          _barColors[index % _barColors.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatDuration(item.value),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: barColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    // Background Bar
                                    Container(
                                      height: 12,
                                      width: constraints.maxWidth,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    // Foreground Animated Bar
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      height: 12,
                                      width: constraints.maxWidth * percentage,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            barColor.withOpacity(0.7),
                                            barColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(percentageTotal * 100).toStringAsFixed(1)}% dari total',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
