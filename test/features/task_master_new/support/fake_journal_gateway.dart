import 'dart:async';

import 'package:rutinitasku/features/task_master_new/domain/repositories/journal_gateway.dart';

class FakeJournalGateway implements JournalGateway {
  FakeJournalGateway({
    this.linkState = JournalLinkState.empty,
    this.loadError,
    this.addError,
    this.subtractError,
  });

  JournalLinkState linkState;
  Object? loadError;
  Object? addError;
  Object? subtractError;

  /// Bila diisi, [addDuration] menunggu completer ini sebelum selesai.
  Completer<JournalAdjustment?>? addCompleter;

  final List<String> addCalls = [];
  final List<JournalAdjustment> subtractCalls = [];
  final List<DateTime> addDates = [];
  final List<DateTime> subtractDates = [];

  @override
  Future<JournalLinkState> loadLinks() async {
    final failure = loadError;
    if (failure != null) throw failure;
    return linkState;
  }

  @override
  Future<JournalAdjustment?> addDuration({
    required String taskId,
    required DateTime at,
  }) async {
    addCalls.add(taskId);
    addDates.add(at);
    final failure = addError;
    if (failure != null) throw failure;
    if (addCompleter != null) return addCompleter!.future;
    if (!linkState.isLinked(taskId)) return null;
    return JournalAdjustment(
      journalTaskId: 'jurnal_$taskId',
      minutes: linkState.incrementMinutes,
    );
  }

  @override
  Future<void> subtractDuration({
    required JournalAdjustment adjustment,
    required DateTime at,
  }) async {
    subtractCalls.add(adjustment);
    subtractDates.add(at);
    final failure = subtractError;
    if (failure != null) throw failure;
  }
}
