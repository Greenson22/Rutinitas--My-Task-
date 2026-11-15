import 'package:flutter/material.dart';

import '../../domain/entities/category.dart' as domain;
import '../../domain/entities/task.dart';
import '../../domain/entities/task_kind.dart';
import '../controllers/task_master_controller.dart';
import '../controllers/task_master_state.dart';
import '../increment_flow.dart';
import '../widgets/action_message_banner.dart';
import '../widgets/status_views.dart';
import '../widgets/task_bulk_actions_dialog.dart';
import '../widgets/task_delete_dialog.dart';
import '../widgets/task_form_dialog.dart';
import '../widgets/task_master_shortcuts.dart';
import '../widgets/task_search_toolbar.dart';
import '../widgets/task_tile.dart';
import 'task_history_screen.dart';

/// Halaman detail kategori untuk mengelola tugas di dalamnya.
///
/// Pada mobile dan tablet layar ini dibuka lewat [Navigator.push]. Pada
/// desktop layar ini ditanam sebagai panel kanan ([embedded]) sehingga tidak
/// membuat rute baru.
class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.controller,
    required this.categoryId,
    this.embedded = false,
    this.onClose,
  });

  final TaskMasterNewController controller;
  final String categoryId;

  /// Menampilkan detail tanpa `Scaffold` agar dapat menjadi panel kanan.
  final bool embedded;

  /// Menutup panel kanan dan kembali ke dashboard pada layout desktop.
  final VoidCallback? onClose;

  @override
  State<CategoryDetailScreen> createState() => CategoryDetailScreenState();
}

/// State publik agar layout desktop dapat mengarahkan shortcut global ke panel
/// detail yang sedang tampil.
class CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final Set<String> _selectedTaskIds = {};
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'taskSearchDetail');
  bool _reorderMode = false;
  bool _bulkActionRunning = false;

  TaskMasterNewController get controller => widget.controller;
  String get categoryId => widget.categoryId;
  bool get _selectionMode => _selectedTaskIds.isNotEmpty;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CategoryDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _selectedTaskIds.clear();
      _reorderMode = false;
      _bulkActionRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final category = controller.categoryById(categoryId);

        if (category == null) {
          return _buildMissingCategory();
        }

        // Pilihan tugas yang sudah tidak ada, misalnya setelah dihapus atau
        // dipindahkan, tidak boleh tetap dihitung sebagai seleksi.
        final availableIds = category.tasks.map((task) => task.id).toSet();
        _selectedTaskIds.removeWhere((id) => !availableIds.contains(id));

        final allTasks = [...category.tasks]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final filtered = state.isSearchActive
            ? controller.filteredTasksIn(category)
            : allTasks;
        final tasks = _reorderMode ? allTasks : filtered;
        final subtitle = _selectionMode
            ? 'Ketuk tugas lain untuk menambah pilihan'
            : state.isSearchActive
            ? '${filtered.length} dari ${allTasks.length} tugas'
            : '${allTasks.length} tugas';

        final body = RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            key: const Key('categoryDetailScrollView'),
            padding: EdgeInsets.fromLTRB(14, 14, 14, widget.embedded ? 24 : 96),
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
              if (allTasks.isNotEmpty && !_reorderMode) ...[
                TaskSearchToolbar(
                  query: controller.searchQuery,
                  filter: controller.taskFilter,
                  onQueryChanged: controller.setSearchQuery,
                  onFilterChanged: controller.setTaskFilter,
                  hintText: 'Cari tugas di kategori ini',
                  focusNode: _searchFocusNode,
                ),
                const SizedBox(height: 12),
              ],
              if (_reorderMode) ...[
                _ReorderHint(onDone: _toggleReorderMode),
                const SizedBox(height: 8),
              ],
              if (allTasks.isEmpty)
                _EmptyTasksView(
                  categoryName: category.name,
                  onAdd: () => _openTaskForm(context),
                )
              else if (tasks.isEmpty)
                SearchEmptyView(onClear: controller.clearSearchAndFilter)
              else
                Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 8, 8),
                    child: _buildTaskList(tasks),
                  ),
                ),
            ],
          ),
        );

        final content = widget.embedded
            ? Column(
                key: const Key('desktopDetailPanel'),
                children: [
                  _buildAppBar(category, subtitle, state),
                  Expanded(child: body),
                ],
              )
            : Scaffold(
                backgroundColor: Colors.grey[100],
                appBar: _buildAppBar(category, subtitle, state),
                floatingActionButton:
                    state.isSaving || _selectionMode || _reorderMode
                    ? null
                    : FloatingActionButton.extended(
                        key: const Key('addTaskButton'),
                        onPressed: () => _openTaskForm(context),
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.add),
                        label: const Text('Tugas'),
                      ),
                body: body,
              );

        return TaskMasterShortcuts(
          onSearch: focusSearch,
          onAdd: openTaskForm,
          onEscape: _handleEscape,
          child: content,
        );
      },
    );
  }

  Widget _buildMissingCategory() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Kategori'),
        leading: widget.onClose == null
            ? null
            : IconButton(
                key: const Key('closeDesktopDetailButton'),
                tooltip: 'Kembali ke dashboard',
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: const Center(child: Text('Kategori tidak ditemukan.')),
    );
  }

  /// Memfokuskan kolom pencarian dari shortcut atau layout desktop.
  void focusSearch() {
    if (_reorderMode) return;
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  /// Membuka form tugas baru dari shortcut `Ctrl/Cmd + N`.
  void openTaskForm() {
    if (controller.state.isSaving || _selectionMode || _reorderMode) return;
    _openTaskForm(context);
  }

  void _handleEscape() {
    if (_selectionMode) {
      _clearSelection();
      return;
    }
    if (_reorderMode) {
      _toggleReorderMode();
      return;
    }
    widget.onClose?.call();
  }

  PreferredSizeWidget _buildAppBar(
    domain.Category category,
    String subtitle,
    TaskMasterNewState state,
  ) {
    return AppBar(
      backgroundColor: Colors.indigo[700],
      foregroundColor: Colors.white,
      automaticallyImplyLeading: !widget.embedded,
      leading: _selectionMode
          ? IconButton(
              key: const Key('exitSelectionButton'),
              tooltip: 'Keluar dari mode seleksi',
              onPressed: _clearSelection,
              icon: const Icon(Icons.close_rounded),
            )
          : widget.embedded && widget.onClose != null
          ? IconButton(
              key: const Key('closeDesktopDetailButton'),
              tooltip: 'Kembali ke dashboard',
              onPressed: widget.onClose,
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectionMode
                ? '${_selectedTaskIds.length} tugas dipilih'
                : '${category.icon} ${category.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      actions: _selectionMode
          ? [
              IconButton(
                key: const Key('bulkActivateButton'),
                tooltip: 'Aktifkan tugas terpilih',
                onPressed: _bulkActionRunning
                    ? null
                    : () => _applyBulkActive(isActive: true),
                icon: const Icon(Icons.play_circle_outline_rounded),
              ),
              IconButton(
                key: const Key('bulkDeactivateButton'),
                tooltip: 'Nonaktifkan tugas terpilih',
                onPressed: _bulkActionRunning
                    ? null
                    : () => _applyBulkActive(isActive: false),
                icon: const Icon(Icons.pause_circle_outline_rounded),
              ),
              IconButton(
                key: const Key('bulkDeleteButton'),
                tooltip: 'Hapus tugas terpilih',
                onPressed: _bulkActionRunning ? null : _confirmBulkDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ]
          : [
              if (widget.embedded)
                IconButton(
                  key: const Key('addTaskButton'),
                  tooltip: shortcutTooltip('Tambah tugas', shortcut: 'Ctrl+N'),
                  onPressed: state.isSaving || _selectionMode || _reorderMode
                      ? null
                      : () => _openTaskForm(context),
                  icon: const Icon(Icons.add_rounded),
                ),
              IconButton(
                key: const Key('reorderTasksButton'),
                tooltip: _reorderMode ? 'Selesai mengurutkan' : 'Urutkan tugas',
                onPressed: state.isSaving ? null : _toggleReorderMode,
                icon: Icon(
                  _reorderMode ? Icons.check_rounded : Icons.swap_vert_rounded,
                ),
              ),
            ],
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) {
        final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
        if (target == oldIndex) return;
        _moveTaskToIndex(tasks[oldIndex], target);
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTaskIds.contains(task.id);
        return Padding(
          key: Key('taskTile_${task.id}'),
          padding: EdgeInsets.only(bottom: index == tasks.length - 1 ? 0 : 1),
          child: TaskTile(
            task: task,
            todayKey: controller.todayKey,
            isJournalLinked: controller.isTaskLinkedToJournal(task.id),
            selectionMode: _selectionMode,
            isSelected: isSelected,
            onLongPress: _reorderMode ? null : () => _toggleSelection(task.id),
            onToggleSelection: () => _toggleSelection(task.id),
            dragHandle: _reorderMode && !controller.state.isSearchActive
                ? ReorderableDragStartListener(
                    key: Key('reorderTaskHandle_${task.id}'),
                    index: index,
                    child: Semantics(
                      label: 'Pegang untuk mengubah urutan ${task.name}',
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        color: Colors.blueGrey,
                      ),
                    ),
                  )
                : null,
            onMoveUp: _reorderMode && index > 0
                ? () => _moveTaskToIndex(task, index - 1)
                : null,
            onMoveDown: _reorderMode && index < tasks.length - 1
                ? () => _moveTaskToIndex(task, index + 1)
                : null,
            onMoveToCategory: _selectionMode || _reorderMode
                ? null
                : () => _moveTaskToCategory(context, task),
            onIncrement: _selectionMode || _reorderMode
                ? null
                : () => _incrementTask(context, task),
            onShowHistory: _selectionMode || _reorderMode
                ? null
                : () => _showTaskHistory(context, task),
            onAction: _selectionMode || _reorderMode
                ? null
                : (action) => _handleTaskAction(context, task, action),
          ),
        );
      },
    );
  }

  void _toggleSelection(String taskId) {
    if (_reorderMode) return;
    setState(() {
      if (!_selectedTaskIds.add(taskId)) {
        _selectedTaskIds.remove(taskId);
      }
    });
  }

  void _clearSelection() {
    if (_selectedTaskIds.isEmpty) return;
    setState(_selectedTaskIds.clear);
  }

  void _toggleReorderMode() {
    if (controller.state.isSaving) return;
    setState(() {
      _reorderMode = !_reorderMode;
      _selectedTaskIds.clear();
    });
    if (_reorderMode) controller.clearSearchAndFilter();
  }

  Future<void> _moveTaskToIndex(Task task, int newIndex) {
    return controller.reorderTask(
      categoryId: categoryId,
      taskId: task.id,
      newIndex: newIndex,
    );
  }

  Future<void> _applyBulkActive({required bool isActive}) async {
    if (_bulkActionRunning) return;
    final ids = [..._selectedTaskIds];
    if (ids.isEmpty) return;
    setState(() => _bulkActionRunning = true);
    final succeeded = await controller.setTasksActive(
      categoryId: categoryId,
      taskIds: ids,
      isActive: isActive,
    );
    if (!mounted) return;
    setState(() {
      _bulkActionRunning = false;
      if (succeeded) _selectedTaskIds.clear();
    });
    if (succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${ids.length} tugas ${isActive ? 'diaktifkan' : 'dinonaktifkan'}.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (_bulkActionRunning || _selectedTaskIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => BulkDeleteTasksDialog(taskCount: _selectedTaskIds.length),
    );
    if (confirmed != true || !mounted) return;

    final ids = [..._selectedTaskIds];
    setState(() => _bulkActionRunning = true);
    final succeeded = await controller.deleteTasks(
      categoryId: categoryId,
      taskIds: ids,
    );
    if (!mounted) return;
    setState(() {
      _bulkActionRunning = false;
      if (succeeded) _selectedTaskIds.clear();
    });
    if (succeeded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${ids.length} tugas dihapus.')));
    }
  }

  Future<void> _showTaskHistory(BuildContext context, Task task) {
    return openTaskHistory(
      context,
      task: task,
      today: DateTime.parse(controller.todayKey),
    );
  }

  /// Increment satu klik tanpa dialog, lalu tampilkan Undo selama 5 detik.
  void _incrementTask(BuildContext context, Task task) {
    incrementTaskWithFeedback(context, controller, task);
  }

  Future<void> _moveTaskToCategory(BuildContext context, Task task) async {
    final data = controller.state.data;
    if (data == null) return;
    final targets =
        data.categories.where((category) => category.id != categoryId).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final targetId = await showDialog<String>(
      context: context,
      builder: (_) => MoveTaskDialog(taskName: task.name, categories: targets),
    );
    if (targetId == null || !context.mounted) return;

    final succeeded = await controller.moveTask(
      fromCategoryId: categoryId,
      taskId: task.id,
      toCategoryId: targetId,
    );
    if (succeeded && context.mounted) {
      final targetName = data.categoryById(targetId)?.name ?? 'kategori tujuan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${task.name}" dipindahkan ke $targetName.')),
      );
    }
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
      case TaskAction.moveToCategory:
        await _moveTaskToCategory(context, task);
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

class _ReorderHint extends StatelessWidget {
  const _ReorderHint({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_vert_rounded, size: 18, color: Colors.indigo),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tarik pegangan untuk mengubah urutan. Tombol panah tersedia '
              'sebagai alternatif.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
          TextButton(
            key: const Key('finishReorderButton'),
            onPressed: onDone,
            child: const Text('Selesai'),
          ),
        ],
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
