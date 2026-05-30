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

  final List<Color> _barColors = [
    Colors.teal,
    Colors.indigo,
    Colors.amber.shade700,
    Colors.pink.shade600,
    Colors.purple.shade600,
    Colors.orange.shade700,
    Colors.cyan.shade700,
    Colors.redAccent,
    Colors.lightGreen.shade700,
    Colors.blue.shade700,
  ];
  List<Map<String, dynamic>> dailyChartData = [];

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
    if (minutes == 0) return '0m';
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h > 0 && m > 0) return '${h}j ${m}m';
    if (h > 0) return '${h}j';
    return '${m}m';
  }

  List<DateTime> _getDaysInRange(DateTime start, DateTime end) {
    List<DateTime> days = [];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      days.add(start.add(Duration(days: i)));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final now = _stripTime(DateTime.now());

    Map<String, int> taskDurations = {};
    Map<String, int> dailyTotals = {};
    Map<String, Map<String, int>> dailyTaskBreakdown =
        {}; // <--- Struktur Data Baru untuk Bar Bertumpuk

    int totalMinutesAll = 0;

    for (var entry in widget.logs) {
      try {
        DateTime date = DateTime.parse(entry.tanggal);
        if (_isDateInRange(date)) {
          String dateKey = entry.tanggal;
          dailyTaskBreakdown.putIfAbsent(dateKey, () => {});

          for (var task in entry.tasks) {
            if (task.durasiMenit > 0) {
              taskDurations[task.nama] =
                  (taskDurations[task.nama] ?? 0) + task.durasiMenit;
              dailyTotals[dateKey] =
                  (dailyTotals[dateKey] ?? 0) + task.durasiMenit;

              // Simpan detail breakdown tugas per hari
              dailyTaskBreakdown[dateKey]![task.nama] =
                  (dailyTaskBreakdown[dateKey]![task.nama] ?? 0) +
                  task.durasiMenit;

              totalMinutesAll += task.durasiMenit;
            }
          }
        }
      } catch (_) {}
    }

    var sortedTaskEntries = taskDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    int maxTaskMinutes = sortedTaskEntries.isNotEmpty
        ? sortedTaskEntries.first.value
        : 1;

    // SINKRONISASI WARNA: Memberikan warna spesifik ke masing-masing nama tugas
    Map<String, Color> taskColorMap = {};
    for (int i = 0; i < sortedTaskEntries.length; i++) {
      taskColorMap[sortedTaskEntries[i].key] =
          _barColors[i % _barColors.length];
    }

    if (_selectedFilter == 'Minggu Ini') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final days = _getDaysInRange(
        startOfWeek,
        startOfWeek.add(const Duration(days: 6)),
      );
      for (var day in days) {
        String key = DateFormat('yyyy-MM-dd').format(day);
        dailyChartData.add({
          'label': DateFormat('E').format(day),
          'subLabel': DateFormat('dd/MM').format(day),
          'minutes': dailyTotals[key] ?? 0,
          'tasks': dailyTaskBreakdown[key] ?? <String, int>{},
        });
      }
    } else if (_selectedFilter == 'Bulan Ini') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      final days = _getDaysInRange(startOfMonth, endOfMonth);
      for (var day in days) {
        String key = DateFormat('yyyy-MM-dd').format(day);
        dailyChartData.add({
          'label': DateFormat('dd').format(day),
          'subLabel': DateFormat('MMM').format(day),
          'minutes': dailyTotals[key] ?? 0,
          'tasks': dailyTaskBreakdown[key] ?? <String, int>{},
        });
      }
    } else if (_selectedFilter == 'Tahun Ini') {
      // Mengisi seluruh hari dari tanggal 1 Januari hingga 31 Desember di tahun berjalan
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31);
      final days = _getDaysInRange(startOfYear, endOfYear);
      for (var day in days) {
        String key = DateFormat('yyyy-MM-dd').format(day);
        dailyChartData.add({
          'label': DateFormat('dd/MM').format(day),
          'subLabel': DateFormat('yy').format(day),
          'minutes': dailyTotals[key] ?? 0,
          'tasks': dailyTaskBreakdown[key] ?? <String, int>{},
        });
      }
    } else if (_selectedFilter == 'Pilih Rentang' && _customRange != null) {
      final days = _getDaysInRange(
        _stripTime(_customRange!.start),
        _stripTime(_customRange!.end),
      );
      for (var day in days) {
        String key = DateFormat('yyyy-MM-dd').format(day);
        dailyChartData.add({
          'label': DateFormat('dd').format(day),
          'subLabel': DateFormat('MM').format(day),
          'minutes': dailyTotals[key] ?? 0,
          'tasks': dailyTaskBreakdown[key] ?? <String, int>{},
        });
      }
    } else {
      // Filter: 'Semua Waktu'
      // Mengambil rentang tanggal penuh dari catatan pertama hingga catatan terakhir
      var sortedKeys = dailyTotals.keys.toList()..sort();
      if (sortedKeys.isNotEmpty) {
        try {
          DateTime minDate = DateTime.parse(sortedKeys.first);
          DateTime maxDate = DateTime.parse(sortedKeys.last);
          final days = _getDaysInRange(minDate, maxDate);
          for (var day in days) {
            String key = DateFormat('yyyy-MM-dd').format(day);
            dailyChartData.add({
              'label': DateFormat('dd/MM').format(day),
              'subLabel': DateFormat('yy').format(day),
              'minutes': dailyTotals[key] ?? 0,
              'tasks': dailyTaskBreakdown[key] ?? <String, int>{},
            });
          }
        } catch (_) {
          // Fallback apabila terjadi kesalahan parsing tanggal
          for (var key in sortedKeys) {
            try {
              DateTime day = DateTime.parse(key);
              dailyChartData.add({
                'label': DateFormat('dd/MM').format(day),
                'subLabel': DateFormat('yy').format(day),
                'minutes': dailyTotals[key] ?? 0,
                'tasks': dailyTaskBreakdown[key] ?? <String, int>{},
              });
            } catch (_) {}
          }
        }
      }
    }

    int maxDailyMinutes = 0;
    for (var data in dailyChartData) {
      if (data['minutes'] > maxDailyMinutes) {
        maxDailyMinutes = data['minutes'];
      }
    }
    if (maxDailyMinutes == 0) maxDailyMinutes = 1;

    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: Colors.indigo[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Statistik & Analitik',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const TabBar(
                    indicatorColor: Colors.amberAccent,
                    indicatorWeight: 3,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: [
                      Tab(
                        text: 'Distribusi Tugas',
                        icon: Icon(Icons.pie_chart_outline, size: 20),
                      ),
                      Tab(
                        text: 'Tren Harian',
                        icon: Icon(Icons.stacked_bar_chart, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
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

            if (_selectedFilter == 'Pilih Rentang' && _customRange != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 2.0,
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Rentang: ${DateFormat('dd MMM yyyy').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customRange!.end)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[600]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Durasi Produktif',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          _formatDuration(totalMinutesAll),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 16),

            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: DISTRIBUSI TUGAS
                  sortedTaskEntries.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data aktivitas.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemCount: sortedTaskEntries.length,
                          itemBuilder: (context, index) {
                            final item = sortedTaskEntries[index];
                            final double percentage =
                                item.value / maxTaskMinutes;
                            final double percentageTotal =
                                item.value / totalMinutesAll;
                            final Color barColor =
                                taskColorMap[item.key] ?? Colors.grey;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
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
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: [
                                          Container(
                                            height: 10,
                                            width: constraints.maxWidth,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 600,
                                            ),
                                            height: 10,
                                            width:
                                                constraints.maxWidth *
                                                percentage,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  barColor.withOpacity(0.7),
                                                  barColor,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 2),
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

                  // TAB 2: GRAFIK TREN HARIAN (BERTUMPUK / STACKED BAR)
                  // TAB 2: GRAFIK TREN HARIAN (BERTUMPUK / STACKED BAR)
                  dailyChartData.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada tren data harian.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.stacked_bar_chart,
                                    size: 16,
                                    color: Colors.indigo[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap batang grafik untuk melihat detail tugas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.indigo[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // === LEGENDA WARNA TUGAS SECARA LANGSUNG (PERBAIKAN) ===
                            if (taskColorMap.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 6.0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 12.0,
                                    runSpacing: 6.0,
                                    children: taskColorMap.entries.map((entry) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: entry.value,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: dailyChartData.map((data) {
                                    final int minutes = data['minutes'];
                                    final Map<String, int> dailyTasks =
                                        data['tasks'];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            minutes > 0
                                                ? _formatDuration(minutes)
                                                : '',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Area Grafik Batang Bertumpuk
                                          Container(
                                            height: 160,
                                            width: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            alignment: Alignment.bottomCenter,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: dailyTasks.entries
                                                    .map((taskEntry) {
                                                      // Hitung tinggi proporsional masing-masing segmen tugas
                                                      final double
                                                      segmentHeight =
                                                          (taskEntry.value /
                                                              maxDailyMinutes) *
                                                          160;
                                                      final Color segColor =
                                                          taskColorMap[taskEntry
                                                              .key] ??
                                                          Colors.indigo;

                                                      return Tooltip(
                                                        message:
                                                            '${taskEntry.key}\n${_formatDuration(taskEntry.value)}',
                                                        triggerMode:
                                                            TooltipTriggerMode
                                                                .tap,
                                                        preferBelow: false,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black87,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    500,
                                                              ),
                                                          height: segmentHeight,
                                                          width: 24,
                                                          decoration: BoxDecoration(
                                                            color: segColor,
                                                            // Berikan garis tepi tipis agar tumpukannya terlihat jelas
                                                            border: Border(
                                                              top: BorderSide(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.5,
                                                                    ),
                                                                width: 0.5,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    })
                                                    .toList()
                                                    .reversed
                                                    .toList(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            data['label'],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            data['subLabel'],
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
