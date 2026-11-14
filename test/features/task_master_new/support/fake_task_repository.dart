import 'dart:async';

import 'package:rutinitasku/features/task_master_new/domain/entities/task_master_data.dart';
import 'package:rutinitasku/features/task_master_new/domain/repositories/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({this.data, this.error});

  TaskMasterData? data;
  Object? error;
  Completer<TaskMasterData>? loadCompleter;
  int loadCount = 0;
  int saveCount = 0;

  @override
  Future<TaskMasterData> load() async {
    loadCount++;
    if (loadCompleter != null) return loadCompleter!.future;
    if (error != null) throw error!;
    return data ?? TaskMasterData.empty();
  }

  @override
  Future<void> save(TaskMasterData data) async {
    saveCount++;
    this.data = data;
  }
}
