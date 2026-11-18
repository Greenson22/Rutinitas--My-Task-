// lib/core/presentation/widgets/task_master_entry.dart

import 'package:flutter/material.dart';

import '../../../features/task_master/presentation/screens/task_master_screen.dart';
import '../../../features/task_master_new/domain/repositories/journal_gateway.dart';
import '../../../features/task_master_new/domain/repositories/task_repository.dart';
import '../../../features/task_master_new/presentation/screens/task_master_screen.dart';
import '../../config/task_master_rollout.dart';

/// Titik masuk tunggal Task Master.
///
/// `main.dart` dan `DrawerMenu` memakai widget ini agar switch navigasi hanya
/// bergantung pada [taskMasterUseNewModule]. Parameter opsional dipakai oleh
/// widget test untuk menyuntikkan fake; produksi memakai nilai default.
class TaskMasterEntry extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (taskMasterUseNewModule) {
      return TaskMasterNewScreen(
        repository: repository,
        journalGateway: journalGateway,
        clock: clock,
      );
    }
    return const HomeScreen();
  }
}
