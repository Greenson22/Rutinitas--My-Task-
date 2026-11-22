// lib/core/presentation/widgets/task_master_entry.dart

import 'package:flutter/material.dart';

import '../../../features/task_master/presentation/screens/task_master_screen.dart';
import '../../../features/task_master_new/domain/repositories/journal_gateway.dart';
import '../../../features/task_master_new/domain/repositories/task_repository.dart';
import '../../../features/task_master_new/presentation/screens/task_master_screen.dart';
import '../../config/task_master_rollout.dart';

/// Titik masuk tunggal Task Master.
///
/// `main.dart` dan `DrawerMenu` memakai widget ini agar pemilihan modul
/// bergantung pada preferensi runtime [taskMasterUseNewModulePrefKey].
/// Hasil pembacaan di-cache selama proses berjalan agar navigasi berulang
/// tidak berkedip. Menampilkan loading ringan jika cache belum tersedia.
class TaskMasterEntry extends StatefulWidget {
  const TaskMasterEntry({
    super.key,
    this.repository,
    this.journalGateway,
    this.clock,
  });

  final TaskRepository? repository;
  final JournalGateway? journalGateway;
  final DateTime Function()? clock;

  @override
  State<TaskMasterEntry> createState() => _TaskMasterEntryState();
}

class _TaskMasterEntryState extends State<TaskMasterEntry> {
  bool? _useNewModule;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final useNew = await getTaskMasterUseNewModule(useCache: true);
    if (mounted) {
      setState(() {
        _useNewModule = useNew;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useNewModule == null) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_useNewModule!) {
      return TaskMasterNewScreen(
        repository: widget.repository,
        journalGateway: widget.journalGateway,
        clock: widget.clock,
      );
    }

    return const HomeScreen();
  }
}
