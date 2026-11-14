import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../data/repositories/task_repository_factory.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/repositories/task_repository.dart';
import '../controllers/task_master_controller.dart';
import '../controllers/task_master_state.dart';
import '../widgets/category_card.dart';
import '../widgets/category_delete_dialog.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/status_views.dart';

/// Task Master New: dashboard dan pengelolaan kategori.
class TaskMasterNewScreen extends StatefulWidget {
  const TaskMasterNewScreen({super.key, this.repository, this.clock});

  /// Dapat diinjeksi pada widget test.
  final TaskRepository? repository;
  final DateTime Function()? clock;

  @override
  State<TaskMasterNewScreen> createState() => _TaskMasterNewScreenState();
}

class _TaskMasterNewScreenState extends State<TaskMasterNewScreen> {
  late final TaskMasterNewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaskMasterNewController(
      repository:
          widget.repository ?? createTaskRepository(clock: widget.clock),
      clock: widget.clock,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task Master New', style: TextStyle(fontSize: 18)),
                Text(
                  'Kelola kategori',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Muat ulang data',
                onPressed: _controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          drawer: const DrawerMenu(isTaskMasterNewActive: true),
          floatingActionButton: state.data == null
              ? null
              : FloatingActionButton.extended(
                  key: const Key('addCategoryButton'),
                  onPressed: state.isSaving ? null : () => _openCategoryForm(),
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Kategori'),
                ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(TaskMasterNewState state) {
    switch (state.status) {
      case TaskMasterNewStatus.loading:
        return const TaskMasterLoadingView();
      case TaskMasterNewStatus.empty:
        return TaskMasterEmptyView(onRefresh: _controller.load);
      case TaskMasterNewStatus.error:
        return TaskMasterErrorView(
          title: state.errorTitle ?? 'Gagal memuat data',
          message: state.errorMessage ?? 'Silakan coba lagi.',
          onRetry: _controller.load,
        );
      case TaskMasterNewStatus.ready:
        return _buildReady(state);
    }
  }

  Widget _buildReady(TaskMasterNewState state) {
    final data = state.data!;
    final categories = [...data.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
        children: [
          if (state.actionMessage != null) ...[
            _ActionMessageBanner(
              message: state.actionMessage!,
              onDismiss: _controller.clearActionMessage,
              onRetry: state.actionRetryable
                  ? _controller.retryLastAction
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          _SummaryCard(data: data),
          const SizedBox(height: 18),
          Text(
            'Kategori',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey[800],
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          for (final category in categories)
            CategoryCard(
              category: category,
              todayKey: _controller.todayKey,
              onAction: (action) => _handleCategoryAction(category, action),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCategoryAction(
    Category category,
    CategoryAction action,
  ) {
    switch (action) {
      case CategoryAction.edit:
        return _openCategoryForm(category: category);
      case CategoryAction.toggleHidden:
        return _controller.setCategoryHidden(
          category.id,
          isHidden: !category.isHidden,
        );
      case CategoryAction.delete:
        return _confirmDeleteCategory(category);
    }
  }

  Future<void> _openCategoryForm({Category? category}) async {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CategoryFormDialog(
        category: category,
        onValidateName: (name) => _controller.validateCategoryName(
          name,
          categoryId: category?.id,
        ),
        onSave: (name, icon) {
          if (category == null) {
            return _controller.addCategory(name: name, icon: icon);
          }
          return _controller.updateCategory(
            categoryId: category.id,
            name: name,
            icon: icon,
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteCategoryDialog(category: category),
    );
    if (confirmed == true) {
      await _controller.deleteCategory(category.id);
    }
  }
}

class _ActionMessageBanner extends StatelessWidget {
  const _ActionMessageBanner({
    required this.message,
    required this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: Colors.amber.shade900,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.brown[800],
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              key: const Key('retryActionButton'),
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          IconButton(
            tooltip: 'Tutup pesan',
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final TaskMasterData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.indigo[700],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        spacing: 22,
        runSpacing: 12,
        children: [
          _SummaryItem(
            label: 'Kategori aktif',
            value: '${data.activeCategoryCount}',
          ),
          _SummaryItem(
            label: 'Total kategori',
            value: '${data.categories.length}',
          ),
          _SummaryItem(label: 'Tugas aktif', value: '${data.activeTaskCount}'),
          _SummaryItem(label: 'Total tugas', value: '${data.allTasks.length}'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
