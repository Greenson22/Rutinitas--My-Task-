import 'package:flutter/material.dart';

import '../domain/entities/task.dart';
import 'controllers/task_master_controller.dart';

const Key incrementSnackBarKey = Key('incrementSnackBar');
const Key undoIncrementActionKey = Key('undoIncrementAction');

/// Menjalankan increment satu klik lalu menampilkan SnackBar Undo.
///
/// Dipakai dashboard dan halaman detail kategori agar keduanya memakai alur
/// yang sama: state berubah seketika, SnackBar 5 detik, dan hanya increment
/// terakhir yang dapat di-undo.
bool incrementTaskWithFeedback(
  BuildContext context,
  TaskMasterNewController controller,
  Task task,
) {
  final applied = controller.incrementTask(
    categoryId: task.categoryId,
    taskId: task.id,
  );
  if (!applied) return false;

  final isLinked = controller.isTaskLinkedToJournal(task.id);
  final message = isLinked
      ? '${task.name} +1 • Jurnal +${controller.journalIncrementMinutes} menit'
      : '${task.name} +1 • Jurnal tidak tertaut';

  final messenger = ScaffoldMessenger.of(context);
  // Ganti SnackBar lama seketika agar Undo selalu merujuk increment terakhir.
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      key: incrementSnackBarKey,
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        key: undoIncrementActionKey,
        label: 'Undo',
        onPressed: controller.undoLastIncrement,
      ),
    ),
  );
  return true;
}
