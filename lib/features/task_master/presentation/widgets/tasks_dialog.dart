import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class TasksDialog extends StatelessWidget {
  final TaskCategory category;

  const TasksDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Text(
              '${category.name} Category',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: category.tasks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Tidak ada tugas aktif di kategori ini.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: category.tasks.length,
                    itemBuilder: (context, index) {
                      final task = category.tasks[index];
                      String subtitleText =
                          '+${task.countToday} / ${task.targetCountToday} hari ini | Total: ${task.count}';
                      if (task.date != null)
                        subtitleText += ' | Due: ${task.date}';

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          task.checked
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: Colors.blue,
                        ),
                        title: Text(
                          task.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          subtitleText,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 11,
                          ),
                        ),
                        trailing: const Icon(Icons.more_vert),
                      );
                    },
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              TextButton(onPressed: () {}, child: const Text('Tambah Tugas')),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
