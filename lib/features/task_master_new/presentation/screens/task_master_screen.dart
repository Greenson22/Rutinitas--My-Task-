import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/adaptive_banner_ad.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../data/repositories/journal_gateway_factory.dart';
import '../../data/repositories/task_repository_factory.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_backup.dart';
import '../../domain/operations/dashboard_summary.dart';
import '../../domain/operations/task_search.dart';
import '../../domain/repositories/journal_gateway.dart';
import '../../domain/repositories/task_repository.dart';
import '../controllers/task_master_controller.dart';
import '../controllers/task_master_state.dart';
import '../increment_flow.dart';
import '../layout/task_master_layout.dart';
import '../models/today_task_sort_mode.dart';
import '../widgets/action_message_banner.dart';
import '../widgets/category_card.dart' show CategoryAction;
import '../widgets/category_delete_dialog.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_reorder_sheet.dart';
import '../widgets/category_summary_card.dart';
import '../widgets/dashboard_summary_cards.dart';
import '../widgets/raw_json_editor_dialog.dart';
import '../widgets/recovery_dialogs.dart';
import '../widgets/status_views.dart';
import '../widgets/task_master_advanced_sheet.dart';
import '../widgets/task_master_shortcuts.dart';
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

  /// Kategori yang sedang ditampilkan pada panel kanan desktop.
  String? _selectedCategoryId;

  /// Pengurutan tugas di Hari Ini.
  TodayTaskSortMode _todaySortMode = TodayTaskSortMode.defaultOrder;
  bool _todayReorderMode = false;
  List<String> _todayCustomOrder = const [];

  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'taskSearch');
  final GlobalKey<CategoryDetailScreenState> _desktopDetailKey =
      GlobalKey<CategoryDetailScreenState>();

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
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final layout = taskMasterLayoutForWidth(
          MediaQuery.sizeOf(context).width,
        );
        final isDesktop = usesTwoPaneLayout(layout);

        return Theme(
          data: Theme.of(context).copyWith(
            focusColor: Colors.indigo.withValues(alpha: 0.24),
            highlightColor: Colors.indigo.withValues(alpha: 0.08),
          ),
          child: TaskMasterShortcuts(
            onSearch: () {
              if (isDesktop && _selectedCategoryId != null) {
                _desktopDetailKey.currentState?.focusSearch();
                return;
              }
              _openSearch();
            },
            onAdd: () {
              if (isDesktop && _selectedCategoryId != null) {
                _desktopDetailKey.currentState?.openTaskForm();
                return;
              }
              _openCategoryForm();
            },
            onEscape: _handleEscape,
            child: Scaffold(
              backgroundColor: Colors.grey[100],
              appBar: AppBar(
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Task Master', style: TextStyle(fontSize: 18)),
                    Text(
                      'Dashboard hari ini',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    key: const Key('openSearchButton'),
                    tooltip: shortcutTooltip(
                      _searchOpen ? 'Tutup pencarian' : 'Cari kategori/tugas',
                      shortcut: 'Ctrl+F',
                    ),
                    onPressed: _toggleSearch,
                    icon: Icon(
                      _searchOpen || state.isSearchActive
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                    ),
                  ),
                  IconButton(
                    key: const Key('reorderCategoriesButton'),
                    tooltip: 'Urutkan kategori',
                    onPressed: state.data == null ? null : _openCategoryReorder,
                    icon: const Icon(Icons.swap_vert_rounded),
                  ),
                  IconButton(
                    key: const Key('advancedButton'),
                    tooltip: 'Advanced',
                    onPressed: _openAdvanced,
                    icon: const Icon(Icons.science_outlined),
                  ),
                ],
              ),
              drawer: const DrawerMenu(),
              floatingActionButton: state.data == null || isDesktop
                  ? null
                  : FloatingActionButton.extended(
                      key: const Key('addCategoryButton'),
                      onPressed: state.isSaving
                          ? null
                          : () => _openCategoryForm(),
                      backgroundColor: Colors.indigo[700],
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add),
                      label: const Text('Kategori'),
                    ),
              bottomNavigationBar:
                  const AdaptiveBannerAd(adKey: 'task_master_banner'),
              body: _buildBody(state, layout),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(TaskMasterNewState state, TaskMasterLayout layout) {
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
          onUnlockWithPin: state.canUnlockWithPin ? _unlockWithPin : null,
          onRestoreBackup: state.offersFileRecovery ? _restoreBackup : null,
          onCreateNewFile: state.offersFileRecovery ? _createNewFile : null,
        );
      case TaskMasterNewStatus.ready:
        return usesTwoPaneLayout(layout)
            ? _buildDesktopReady(state)
            : _buildSinglePaneReady(state);
    }
  }

  Widget _buildSinglePaneReady(TaskMasterNewState state) {
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: taskMasterSinglePaneMaxWidth,
        ),
        child: RefreshIndicator(
          onRefresh: _controller.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    focusNode: _searchFocusNode,
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
                    todayTasksTotalCount: todayTasks.length,
                    journalMinutesToday: _controller.journalTodayMinutes,
                  ),
                  const SizedBox(height: 20),
                  _TodaySectionHeader(
                    taskCount: todayTasks.length,
                    sortMode: _todaySortMode,
                    isReorderMode: _todayReorderMode,
                    onSortModeChanged: (mode) {
                      setState(() {
                        _todaySortMode = mode;
                        if (mode != TodayTaskSortMode.custom) {
                          _todayReorderMode = false;
                        }
                      });
                    },
                    onToggleReorderMode: () {
                      setState(() {
                        _todayReorderMode = !_todayReorderMode;
                        if (_todayReorderMode) {
                          _todaySortMode = TodayTaskSortMode.custom;
                          final sorted = sortTodayTasks(
                            todayTasks,
                            mode: _todaySortMode,
                            todayKey: todayKey,
                            customOrder: _todayCustomOrder,
                          );
                          _todayCustomOrder = sorted.map((e) => e.task.id).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  if (todayTasks.isEmpty)
                    const EmptyTodayTasksView()
                  else
                    _buildTodayCard(todayTasks, todayKey),
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
                        onAction: (action) =>
                            _handleCategoryAction(category, action),
                        onOpen: () => _openCategoryDetail(category),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(List<TodayTaskEntry> rawTodayTasks, String todayKey) {
    final todayTasks = sortTodayTasks(
      rawTodayTasks,
      mode: _todaySortMode,
      todayKey: todayKey,
      customOrder: _todayCustomOrder,
    );

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: _todayReorderMode
            ? ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: todayTasks.length,
                onReorder: (oldIndex, newIndex) {
                  final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
                  if (target == oldIndex) return;
                  _reorderTodayTask(todayTasks, oldIndex, target);
                },
                itemBuilder: (context, i) {
                  final item = todayTasks[i];
                  return Column(
                    key: Key('todayReorderTaskItem_${item.task.id}'),
                    children: [
                      if (i > 0) const Divider(height: 1),
                      TodayTaskTile(
                        entry: item,
                        todayKey: todayKey,
                        isJournalLinked: _controller.isTaskLinkedToJournal(
                          item.task.id,
                        ),
                        isReorderMode: true,
                        dragHandle: ReorderableDragStartListener(
                          index: i,
                          child: Semantics(
                            label: 'Pegang untuk mengubah urutan ${item.task.name}',
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                        ),
                        onMoveUp: i > 0
                            ? () => _reorderTodayTask(todayTasks, i, i - 1)
                            : null,
                        onMoveDown: i < todayTasks.length - 1
                            ? () => _reorderTodayTask(todayTasks, i, i + 1)
                            : null,
                        onIncrement: () {},
                      ),
                    ],
                  );
                },
              )
            : Column(
                children: [
                  for (var i = 0; i < todayTasks.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    TodayTaskTile(
                      entry: todayTasks[i],
                      todayKey: todayKey,
                      isJournalLinked: _controller.isTaskLinkedToJournal(
                        todayTasks[i].task.id,
                      ),
                      onChangeVisibility: (visibility) {
                        _controller.setTaskVisibility(
                          categoryId: todayTasks[i].category.id,
                          taskId: todayTasks[i].task.id,
                          todayVisibility: visibility,
                        );
                      },
                      onIncrement: () => incrementTaskWithFeedback(
                        context,
                        _controller,
                        todayTasks[i].task,
                      ),
                      onShowHistory: () => _showTaskHistory(todayTasks[i].task),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  void _reorderTodayTask(
    List<TodayTaskEntry> currentList,
    int oldIndex,
    int newIndex,
  ) {
    final list = List<TodayTaskEntry>.from(currentList);
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    setState(() {
      _todaySortMode = TodayTaskSortMode.custom;
      _todayCustomOrder = list.map((e) => e.task.id).toList();
    });
  }

  /// Layout desktop: daftar kategori di kiri dan dashboard/detail di kanan.
  Widget _buildDesktopReady(TaskMasterNewState state) {
    final data = state.data!;
    final selectedCategory = _selectedCategoryId == null
        ? null
        : data.categoryById(_selectedCategoryId!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDesktopSidebar(state),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          key: const Key('desktopRightPanel'),
          child: selectedCategory == null
              ? _buildDesktopDashboard(state)
              : CategoryDetailScreen(
                  key: _desktopDetailKey,
                  controller: _controller,
                  categoryId: selectedCategory.id,
                  embedded: true,
                  onClose: _closeDesktopDetail,
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(TaskMasterNewState state) {
    final data = state.data!;
    final categories = visibleCategories(data, includeHidden: _showHidden);
    final sidebarWidth = (MediaQuery.sizeOf(context).width * 0.26)
        .clamp(260.0, 340.0)
        .toDouble();

    return Container(
      key: const Key('desktopCategorySidebar'),
      width: sidebarWidth,
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          ListTile(
            key: const Key('desktopDashboardTile'),
            selected: _selectedCategoryId == null,
            selectedTileColor: Colors.indigo.withValues(alpha: 0.08),
            leading: const Icon(Icons.today_rounded, color: Colors.indigo),
            title: const Text(
              'Hari Ini',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Dashboard dan ringkasan'),
            onTap: _closeDesktopDetail,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'KATEGORI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('addCategoryButton'),
                  tooltip: shortcutTooltip(
                    'Tambah kategori',
                    shortcut: 'Ctrl+N',
                  ),
                  onPressed: state.isSaving ? null : () => _openCategoryForm(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ),
          ),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Belum ada kategori yang ditampilkan.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
              ),
            )
          else
            for (final category in categories)
              ListTile(
                key: Key('desktopCategoryTile_${category.id}'),
                selected: _selectedCategoryId == category.id,
                selectedTileColor: Colors.indigo.withValues(alpha: 0.08),
                leading: CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.08),
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                title: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${categoryActiveTaskCount(category)} tugas aktif',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton<CategoryAction>(
                  key: Key('desktopCategoryMenu_${category.id}'),
                  tooltip: 'Aksi kategori ${category.name}',
                  onSelected: (action) =>
                      _handleCategoryAction(category, action),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: CategoryAction.edit,
                      child: Text('Ubah'),
                    ),
                    PopupMenuItem(
                      value: CategoryAction.toggleHidden,
                      child: Text(
                        category.isHidden ? 'Tampilkan' : 'Sembunyikan',
                      ),
                    ),
                    const PopupMenuItem(
                      value: CategoryAction.delete,
                      child: Text('Hapus'),
                    ),
                  ],
                ),
                onTap: () => _openCategoryDetail(category),
              ),
          const Divider(height: 1),
          ListTile(
            key: const Key('desktopShowHiddenToggle'),
            leading: Icon(
              _showHidden ? Icons.visibility : Icons.visibility_off_outlined,
              color: Colors.blueGrey,
            ),
            title: const Text('Tampilkan tersembunyi'),
            trailing: Switch(
              value: _showHidden,
              onChanged: (value) => setState(() => _showHidden = value),
            ),
            onTap: () => setState(() => _showHidden = !_showHidden),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDashboard(TaskMasterNewState state) {
    final data = state.data!;
    final todayKey = _controller.todayKey;
    final todayTasks = collectTodayTasks(
      data,
      todayKey,
      includeHidden: _showHidden,
    );
    final completedTargets = completedTargetCount(
      collectTodayTasks(data, todayKey),
      todayKey,
    );

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        key: const Key('desktopDashboard'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
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
              focusNode: _searchFocusNode,
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
              todayTasksTotalCount: todayTasks.length,
              journalMinutesToday: _controller.journalTodayMinutes,
            ),
            const SizedBox(height: 20),
            _TodaySectionHeader(
              taskCount: todayTasks.length,
              sortMode: _todaySortMode,
              isReorderMode: _todayReorderMode,
              onSortModeChanged: (mode) {
                setState(() {
                  _todaySortMode = mode;
                  if (mode != TodayTaskSortMode.custom) {
                    _todayReorderMode = false;
                  }
                });
              },
              onToggleReorderMode: () {
                setState(() {
                  _todayReorderMode = !_todayReorderMode;
                  if (_todayReorderMode) {
                    _todaySortMode = TodayTaskSortMode.custom;
                    final sorted = sortTodayTasks(
                      todayTasks,
                      mode: _todaySortMode,
                      todayKey: todayKey,
                      customOrder: _todayCustomOrder,
                    );
                    _todayCustomOrder = sorted.map((e) => e.task.id).toList();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            if (todayTasks.isEmpty)
              const EmptyTodayTasksView()
            else
              _buildTodayCard(todayTasks, todayKey),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Colors.indigo.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 18,
                      color: Colors.indigo,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pilih kategori di panel kiri untuk melihat dan '
                        'mengelola tugasnya. Ctrl+F mencari, Ctrl+N menambah.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _closeDesktopDetail() {
    if (_selectedCategoryId == null) return;
    setState(() => _selectedCategoryId = null);
  }

  void _openSearch() {
    if (!_searchOpen) setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });
  }

  void _handleEscape() {
    if (_searchOpen || _controller.isSearchActive) {
      _clearSearch();
      return;
    }
    _closeDesktopDetail();
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

  Future<void> _openCategoryReorder() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CategoryReorderSheet(controller: _controller),
    );
  }

  Future<void> _openAdvanced() async {
    final action = await showModalBottomSheet<_AdvancedAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => TaskMasterAdvancedSheet(
        onOpenRawJsonEditor: () =>
            Navigator.of(sheetContext).pop(_AdvancedAction.rawJson),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _AdvancedAction.rawJson:
        await _openRawJsonEditor();
      case null:
        break;
    }
  }

  Future<void> _openRawJsonEditor() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => RawJsonEditorDialog(
        loadContent: _controller.readRawJson,
        onSave: _controller.saveRawJson,
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON berhasil disimpan dengan atomic write.'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Future<void> _unlockWithPin() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => TaskMasterPinDialog(onUnlock: _controller.unlockWithPin),
    );
  }

  Future<void> _restoreBackup() async {
    final backups = await _controller.listBackups();
    if (!mounted) return;
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada backup. Gunakan "Buat file baru" atau masukkan PIN.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showDialog<TaskBackup>(
      context: context,
      builder: (_) => TaskMasterBackupDialog(backups: backups),
    );
    if (!mounted || selected == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => TaskMasterRestoreConfirmDialog(backup: selected),
    );
    if (!mounted || confirmed != true) return;

    final restored = await _controller.restoreBackup(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Backup berhasil dipulihkan.'
              : 'Backup gagal dipulihkan. Data saat ini tetap aman.',
        ),
        backgroundColor: restored ? Colors.teal : Colors.redAccent,
      ),
    );
  }

  Future<void> _createNewFile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const TaskMasterCreateNewFileDialog(),
    );
    if (!mounted || confirmed != true) return;

    final created = await _controller.createNewFile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'File baru dibuat. Backup file lama tersedia untuk dipulihkan.'
              : 'File baru gagal dibuat. Data lama tidak diubah.',
        ),
        backgroundColor: created ? Colors.teal : Colors.redAccent,
      ),
    );
  }

  void _toggleSearch() {
    final layout = taskMasterLayoutForWidth(MediaQuery.sizeOf(context).width);
    if (usesTwoPaneLayout(layout) && _selectedCategoryId != null) {
      _desktopDetailKey.currentState?.focusSearch();
      return;
    }
    if (_searchOpen || _controller.isSearchActive) {
      _clearSearch();
      return;
    }
    _openSearch();
  }

  void _clearSearch() {
    _controller.clearSearchAndFilter();
    if (_searchOpen) setState(() => _searchOpen = false);
    if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();
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

    final layout = taskMasterLayoutForWidth(MediaQuery.sizeOf(context).width);
    if (usesTwoPaneLayout(layout)) {
      // Desktop memakai panel kanan, bukan push screen.
      setState(() => _selectedCategoryId = category.id);
      return;
    }

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
    if (confirmed != true) return;
    final succeeded = await _controller.deleteCategory(category.id);
    if (succeeded && mounted && _selectedCategoryId == category.id) {
      setState(() => _selectedCategoryId = null);
    }
  }
}

class _TodaySectionHeader extends StatelessWidget {
  const _TodaySectionHeader({
    required this.taskCount,
    required this.sortMode,
    required this.isReorderMode,
    required this.onSortModeChanged,
    required this.onToggleReorderMode,
  });

  final int taskCount;
  final TodayTaskSortMode sortMode;
  final bool isReorderMode;
  final ValueChanged<TodayTaskSortMode> onSortModeChanged;
  final VoidCallback onToggleReorderMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Hari Ini',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey[800],
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (taskCount > 0) ...[
          IconButton(
            key: const Key('todayReorderButton'),
            tooltip: isReorderMode ? 'Selesai atur urutan' : 'Atur urutan manual',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleReorderMode,
            icon: Icon(
              isReorderMode ? Icons.check_rounded : Icons.swap_vert_rounded,
              size: 20,
              color: isReorderMode ? Colors.indigo : Colors.blueGrey,
            ),
          ),
          PopupMenuButton<TodayTaskSortMode>(
            key: const Key('todaySortMenuButton'),
            tooltip: 'Urutkan tugas Hari Ini',
            icon: const Icon(Icons.sort_rounded, size: 20, color: Colors.blueGrey),
            onSelected: onSortModeChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: TodayTaskSortMode.defaultOrder,
                child: Row(
                  children: [
                    if (sortMode == TodayTaskSortMode.defaultOrder)
                      const Icon(Icons.check, size: 18, color: Colors.indigo)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Urutan bawaan (Kategori)')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TodayTaskSortMode.incompleteFirst,
                child: Row(
                  children: [
                    if (sortMode == TodayTaskSortMode.incompleteFirst)
                      const Icon(Icons.check, size: 18, color: Colors.indigo)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Belum tercapai di atas')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TodayTaskSortMode.completedFirst,
                child: Row(
                  children: [
                    if (sortMode == TodayTaskSortMode.completedFirst)
                      const Icon(Icons.check, size: 18, color: Colors.indigo)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Target tercapai di atas')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TodayTaskSortMode.nameAsc,
                child: Row(
                  children: [
                    if (sortMode == TodayTaskSortMode.nameAsc)
                      const Icon(Icons.check, size: 18, color: Colors.indigo)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Nama tugas (A-Z)')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TodayTaskSortMode.nameDesc,
                child: Row(
                  children: [
                    if (sortMode == TodayTaskSortMode.nameDesc)
                      const Icon(Icons.check, size: 18, color: Colors.indigo)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Nama tugas (Z-A)')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TodayTaskSortMode.categoryAsc,
                child: Row(
                  children: [
                    if (sortMode == TodayTaskSortMode.categoryAsc)
                      const Icon(Icons.check, size: 18, color: Colors.indigo)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Nama kategori (A-Z)')),
                  ],
                ),
              ),
              if (sortMode == TodayTaskSortMode.custom)
                const PopupMenuItem(
                  value: TodayTaskSortMode.custom,
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 18, color: Colors.indigo),
                      SizedBox(width: 8),
                      Expanded(child: Text('Urutan manual (Kustom)')),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        Text(
          '$taskCount tugas',
          style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
        ),
      ],
    );
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

enum _AdvancedAction { rawJson }

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
        Flexible(
          child: TextButton.icon(
            key: const Key('showHiddenToggle'),
            onPressed: onToggleHidden,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
              foregroundColor: showHidden ? Colors.indigo : Colors.blueGrey,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: Icon(
              showHidden ? Icons.visibility : Icons.visibility_off_outlined,
              size: 17,
            ),
            label: Text(
              'Tampilkan tersembunyi',
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: showHidden ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
