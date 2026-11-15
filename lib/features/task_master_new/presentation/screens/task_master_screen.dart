import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../data/repositories/journal_gateway_factory.dart';
import '../../data/repositories/task_repository_factory.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/task.dart';
import '../../domain/operations/dashboard_summary.dart';
import '../../domain/operations/task_search.dart';
import '../../domain/repositories/journal_gateway.dart';
import '../../domain/repositories/task_repository.dart';
import '../controllers/task_master_controller.dart';
import '../controllers/task_master_state.dart';
import '../increment_flow.dart';
import '../widgets/action_message_banner.dart';
import '../widgets/category_card.dart' show CategoryAction;
import '../widgets/category_delete_dialog.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_summary_card.dart';
import '../widgets/dashboard_summary_cards.dart';
import '../widgets/status_views.dart';
import '../widgets/task_search_toolbar.dart';
import '../widgets/task_tile.dart';
import '../widgets/today_task_tile.dart';
import 'category_detail_screen.dart';
import 'task_history_screen.dart';

/// Task Master New: dashboard dan pengelolaan kategori.
class TaskMasterNewScreen extends StatefulWidget {
  const TaskMasterNewScreen({
    super.key,
    this.repository,
    this.journalGateway,
    this.clock,
  });

  /// Dapat diinjeksi pada widget test.
  final TaskRepository? repository;
  final JournalGateway? journalGateway;
  final DateTime Function()? clock;

  @override
  State<TaskMasterNewScreen> createState() => _TaskMasterNewScreenState();
}

class _TaskMasterNewScreenState extends State<TaskMasterNewScreen> {
  late final TaskMasterNewController _controller;

  /// Mode "Tampilkan tersembunyi" hanya berlaku di layar ini.
  bool _showHidden = false;

  /// Kolom pencarian dibuka lewat ikon agar dashboard tetap ringkas.
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    final journalGateway =
        widget.journalGateway ??
        (widget.repository == null
            ? createJournalGateway(clock: widget.clock)
            : null);
    _controller = TaskMasterNewController(
      repository:
          widget.repository ?? createTaskRepository(clock: widget.clock),
      journalGateway: journalGateway,
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
                  'Dashboard hari ini',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('openSearchButton'),
                tooltip: _searchOpen
                    ? 'Tutup pencarian'
                    : 'Cari kategori/tugas',
                onPressed: _toggleSearch,
                icon: Icon(
                  _searchOpen || state.isSearchActive
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
                ),
              ),
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
        return TaskMasterEmptyView(
          onRefresh: _controller.load,
          onCreateCategory: () => _openCategoryForm(),
        );
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
    final todayKey = _controller.todayKey;
    final visible = visibleCategories(data, includeHidden: _showHidden);
    final todayTasks = collectTodayTasks(
      data,
      todayKey,
      includeHidden: _showHidden,
    );
    // Ringkasan selalu menghitung kategori tersembunyi sebagai tidak aktif,
    // sehingga mode "Tampilkan tersembunyi" tidak mengubah angka ringkasan.
    final completedTargets = completedTargetCount(
      collectTodayTasks(data, todayKey),
      todayKey,
    );

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
        children: [
          if (state.actionMessage != null) ...[
            ActionMessageBanner(
              message: state.actionMessage!,
              onDismiss: _controller.clearActionMessage,
              onRetry: state.actionRetryable
                  ? _controller.retryLastAction
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          if (_searchOpen || state.isSearchActive) ...[
            TaskSearchToolbar(
              query: _controller.searchQuery,
              filter: _controller.taskFilter,
              onQueryChanged: _controller.setSearchQuery,
              onFilterChanged: _controller.setTaskFilter,
            ),
            const SizedBox(height: 16),
          ],
          if (state.isSearchActive)
            ..._buildSearchResults(state, todayKey)
          else ...[
            DashboardSummaryCards(
              activeCategoryCount: data.activeCategoryCount,
              activeTaskCount: data.activeTaskCount,
              completedTargetsToday: completedTargets,
              journalMinutesToday: _controller.journalTodayMinutes,
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Hari Ini',
              trailing: '${todayTasks.length} tugas',
            ),
            const SizedBox(height: 8),
            if (todayTasks.isEmpty)
              const EmptyTodayTasksView()
            else
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < todayTasks.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        TodayTaskTile(
                          entry: todayTasks[i],
                          todayKey: todayKey,
                          isJournalLinked: _controller.isTaskLinkedToJournal(
                            todayTasks[i].task.id,
                          ),
                          onIncrement: () => incrementTaskWithFeedback(
                            context,
                            _controller,
                            todayTasks[i].task,
                          ),
                          onShowHistory: () =>
                              _showTaskHistory(todayTasks[i].task),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _CategorySectionHeader(
              showHidden: _showHidden,
              onToggleHidden: () {
                setState(() => _showHidden = !_showHidden);
              },
            ),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              HiddenCategoriesView(
                onShowHidden: () => setState(() => _showHidden = true),
              )
            else
              for (final category in visible)
                CategorySummaryCard(
                  category: category,
                  todayKey: todayKey,
                  onAction: (action) => _handleCategoryAction(category, action),
                  onOpen: () => _openCategoryDetail(category),
                ),
          ],
        ],
      ),
    );
  }

  /// Hasil pencarian dikelompokkan per kategori agar konteks tetap jelas.
  List<Widget> _buildSearchResults(TaskMasterNewState state, String todayKey) {
    final groups = _controller.searchGroups(includeHidden: _showHidden);
    if (groups.isEmpty) {
      return [SearchEmptyView(onClear: _clearSearch)];
    }

    final total = groups.fold<int>(0, (sum, group) => sum + group.tasks.length);
    return [
      _SectionHeader(
        title: state.searchQuery.isEmpty ? 'Hasil filter' : 'Hasil pencarian',
        trailing: '$total tugas',
      ),
      const SizedBox(height: 8),
      for (final group in groups) _buildSearchGroup(group, todayKey),
    ];
  }

  Widget _buildSearchGroup(TaskSearchGroup group, String todayKey) {
    final category = group.category;
    return Card(
      key: Key('searchGroup_${category.id}'),
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: Key('searchGroupOpen_${category.id}'),
            onTap: () => _openCategoryDetail(category),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.indigo.withValues(alpha: 0.08),
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${group.tasks.length} tugas cocok',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 8, 6),
            child: Column(
              children: [
                for (var i = 0; i < group.tasks.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  TaskTile(
                    key: Key('taskTile_${group.tasks[i].id}'),
                    task: group.tasks[i],
                    todayKey: todayKey,
                    isJournalLinked: _controller.isTaskLinkedToJournal(
                      group.tasks[i].id,
                    ),
                    onIncrement: () => incrementTaskWithFeedback(
                      context,
                      _controller,
                      group.tasks[i],
                    ),
                    onShowHistory: () => _showTaskHistory(group.tasks[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    if (_searchOpen || _controller.isSearchActive) {
      _clearSearch();
      return;
    }
    setState(() => _searchOpen = true);
  }

  void _clearSearch() {
    _controller.clearSearchAndFilter();
    if (_searchOpen) setState(() => _searchOpen = false);
  }

  Future<void> _showTaskHistory(Task task) {
    return openTaskHistory(
      context,
      task: task,
      today: DateTime.parse(_controller.todayKey),
    );
  }

  Future<void> _openCategoryDetail(Category category) async {
    // Detail kategori selalu dibuka dengan daftar yang tidak tersaring, agar
    // pengguna melihat seluruh tugas di kategori tersebut.
    _clearSearch();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(
          controller: _controller,
          categoryId: category.id,
        ),
      ),
    );
    // Pencarian yang diketik di halaman detail tidak boleh ikut menyaring
    // dashboard saat pengguna kembali.
    if (mounted) _clearSearch();
  }

  Future<void> _handleCategoryAction(Category category, CategoryAction action) {
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
        onValidateName: (name) =>
            _controller.validateCategoryName(name, categoryId: category?.id),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey[800],
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
          ),
      ],
    );
  }
}

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({
    required this.showHidden,
    required this.onToggleHidden,
  });

  final bool showHidden;
  final VoidCallback onToggleHidden;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Kategori',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey[800],
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextButton.icon(
          key: const Key('showHiddenToggle'),
          onPressed: onToggleHidden,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: showHidden ? Colors.indigo : Colors.blueGrey,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: Icon(
            showHidden ? Icons.visibility : Icons.visibility_off_outlined,
            size: 17,
          ),
          label: Text(
            'Tampilkan tersembunyi',
            style: TextStyle(
              fontSize: 11,
              fontWeight: showHidden ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
