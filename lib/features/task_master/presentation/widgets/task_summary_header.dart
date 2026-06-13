// lib/features/task_master/presentation/widgets/task_summary_header.dart

import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class TaskSummaryHeader extends StatelessWidget {
  final List<TaskCategory> allCategoriesRaw;
  final List<TaskCategory> visibleCategories;
  final String totalJurnalDurationString;

  const TaskSummaryHeader({
    super.key,
    required this.allCategoriesRaw,
    required this.visibleCategories,
    required this.totalJurnalDurationString,
  });

  @override
  Widget build(BuildContext context) {
    int totalCategories = allCategoriesRaw.length;
    int visibleCategoriesCount = visibleCategories.length;
    int totalTasks = 0;
    int completedTasksToday = 0;
    int tasksWithTargetToday = 0;

    for (var category in allCategoriesRaw) {
      for (var task in category.tasks) {
        if (task.isActive) {
          totalTasks++;
          if (task.targetCountToday > 0) {
            tasksWithTargetToday++;
            if (task.countToday >= task.targetCountToday) {
              completedTasksToday++;
            }
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize,
                color: Colors.indigo[700],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Tugas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          LayoutBuilder(
            builder: (context, boxConstraints) {
              bool isMobile = boxConstraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildItemCard(
                            'Kategori',
                            '$visibleCategoriesCount Active',
                            'Total: $totalCategories',
                            Colors.blue[50]!,
                            Colors.blue[900]!,
                            Colors.blue[700]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildItemCard(
                            'Total Tugas',
                            '$totalTasks Unit',
                            'Di semua kategori',
                            Colors.amber[50]!,
                            Colors.amber[900]!,
                            Colors.amber[800]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildItemCard(
                            'Selesai Hari Ini',
                            '$completedTasksToday / $tasksWithTargetToday',
                            'Target tercapai',
                            Colors.green[50]!,
                            Colors.green[900]!,
                            Colors.green[800]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildItemCard(
                            'Jam Hari Ini',
                            totalJurnalDurationString,
                            'Durasi pengerjaan',
                            Colors.teal[50]!,
                            Colors.teal[900]!,
                            Colors.teal[800]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildItemCard(
                        'Kategori',
                        '$visibleCategoriesCount Active',
                        'Total: $totalCategories',
                        Colors.blue[50]!,
                        Colors.blue[900]!,
                        Colors.blue[700]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildItemCard(
                        'Total Tugas',
                        '$totalTasks Unit',
                        'Di semua kategori',
                        Colors.amber[50]!,
                        Colors.amber[900]!,
                        Colors.amber[800]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildItemCard(
                        'Selesai Hari Ini',
                        '$completedTasksToday / $tasksWithTargetToday',
                        'Target tercapai',
                        Colors.green[50]!,
                        Colors.green[900]!,
                        Colors.green[800]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildItemCard(
                        'Jam Hari Ini',
                        totalJurnalDurationString,
                        'Durasi pengerjaan',
                        Colors.teal[50]!,
                        Colors.teal[900]!,
                        Colors.teal[800]!,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    String title,
    String mainText,
    String subText,
    Color bgColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            mainText,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subText,
            style: TextStyle(color: subTextColor, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
