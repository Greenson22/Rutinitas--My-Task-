import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../data/repositories/task_repository_factory.dart';
import '../../domain/entities/task_master_data.dart';
import '../../domain/repositories/task_repository.dart';
import '../controllers/task_master_controller.dart';
import '../controllers/task_master_state.dart';
import '../widgets/category_read_only_card.dart';
import '../widgets/status_views.dart';

/// Task Master New versi fondasi: menampilkan data hasil migrasi secara
/// baca-saja.
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
                  'Tampilan baca-saja',
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
          body: _buildBody(_controller.state),
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
        return _buildReady(state.data!);
    }
  }

  Widget _buildReady(TaskMasterData data) {
    final categories = [...data.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          const _ReadOnlyBanner(),
          const SizedBox(height: 14),
          _SummaryCard(data: data),
          const SizedBox(height: 18),
          for (final category in categories)
            CategoryReadOnlyCard(
              category: category,
              todayKey: _controller.todayKey,
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.08),
            Colors.teal.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_open_rounded, color: Colors.indigo, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data lama sudah dimigrasikan ke skema v2 dan ditampilkan '
              'baca-saja. Pengelolaan kategori dan tugas akan tersedia pada '
              'tahap berikutnya.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.blueGrey[800],
              ),
            ),
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
