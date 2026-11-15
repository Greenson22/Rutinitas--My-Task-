import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../controllers/task_master_controller.dart';
import '../widgets/action_message_banner.dart';
import '../widgets/task_delete_dialog.dart';
import '../widgets/task_form_dialog.dart';
import '../widgets/task_tile.dart';

/// Halaman detail kategori untuk mengelola tugas di dalamnya.
class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.controller,
    required this.categoryId,
  });

  final TaskMasterNewController controller;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final category = controller.categoryById(categoryId);

        if (category == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.indigo[700],
              foregroundColor: Colors.white,
              title: const Text('Kategori'),
            ),
            body: const Center(child: Text('Kategori tidak ditemukan.')),
          );
        }

        final tasks = [...category.tasks]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.icon} ${category.name}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  '${tasks.length} tugas',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('addTaskButton'),
            onPressed: state.isSaving ? null : () => _openTaskForm(context),
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Tugas'),
          ),
          body: RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
              children: [
                if (state.actionMessage != null) ...[
                  ActionMessageBanner(
                    message: state.actionMessage!,
                    onDismiss: controller.clearActionMessage,
                    onRetry: state.actionRetryable
                        ? controller.retryLastAction
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                if (tasks.isEmpty)
                  _EmptyTasksView(
                    categoryName: category.name,
                    onAdd: () => _openTaskForm(context),
                  )
                else
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < tasks.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            TaskTile(
                              key: Key('taskTile_${tasks[i].id}'),
                              task: tasks[i],
                              todayKey: controller.todayKey,
                              isJournalLinked: controller.isTaskLinkedToJournal(
                                tasks[i].id,
                              ),
                              onIncrement: () =>
                                  _incrementTask(context, tasks[i]),
                              onAction: (action) =>
                                  _handleTaskAction(context, tasks[i], action),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Increment satu klik tanpa dialog, lalu tampilkan Undo selama 5 detik.
  void _incrementTask(BuildContext context, Task task) {
    final applied = controller.incrementTask(
      categoryId: categoryId,
      taskId: task.id,
    );
    if (!applied) return;

    final isLinked = controller.isTaskLinkedToJournal(task.id);
    final message = isLinked
        ? '${task.name} +1 • Jurnal +${controller.journalIncrementMinutes} menit'
        : '${task.name} +1 • Jurnal tidak tertaut';

    final messenger = ScaffoldMessenger.of(context);
    // Ganti SnackBar lama seketika agar Undo selalu merujuk increment terakhir.
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('incrementSnackBar'),
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          key: const Key('undoIncrementAction'),
          label: 'Undo',
          onPressed: controller.undoLastIncrement,
        ),
      ),
    );
  }

  Future<void> _handleTaskAction(
    BuildContext context,
    Task task,
    TaskAction action,
  ) async {
    switch (action) {
      case TaskAction.edit:
        await _openTaskForm(context, task: task);
        return;
      case TaskAction.toggleActive:
        await controller.setTaskActive(
          categoryId: categoryId,
          taskId: task.id,
          isActive: !task.isActive,
        );
        return;
      case TaskAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => DeleteTaskDialog(task: task),
        );
        if (confirmed == true) {
          await controller.deleteTask(categoryId: categoryId, taskId: task.id);
        }
        return;
    }
  }

  Future<void> _openTaskForm(BuildContext context, {Task? task}) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => TaskFormDialog(
        task: task,
        onValidateName: controller.validateTaskName,
        failureMessage: () => controller.state.actionMessage,
        onSave:
            ({
              required String name,
              required TaskKind kind,
              required int targetDaily,
              required int targetTotal,
              required bool isActive,
            }) {
              if (task == null) {
                return controller.addTask(
                  categoryId: categoryId,
                  name: name,
                  kind: kind,
                  targetDaily: targetDaily,
                  targetTotal: targetTotal,
                  isActive: isActive,
                );
              }
              return controller.updateTask(
                categoryId: categoryId,
                taskId: task.id,
                name: name,
                kind: kind,
                targetDaily: targetDaily,
                targetTotal: targetTotal,
                isActive: isActive,
              );
            },
      ),
    );
  }
}

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView({required this.categoryName, required this.onAdd});

  final String categoryName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_add_rounded,
              size: 44,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada tugas',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan tugas pertama untuk kategori "$categoryName". '
            'Pilih Kebiasaan, Hitungan, atau Progres sesuai cara Anda '
            'melacaknya.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('emptyAddTaskButton'),
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah tugas'),
          ),
        ],
      ),
    );
  }
}
