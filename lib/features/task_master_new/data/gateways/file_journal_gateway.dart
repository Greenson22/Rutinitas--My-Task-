import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';
import 'package:rutinitasku/core/utils/crypto_helper.dart';

import '../../domain/repositories/journal_gateway.dart';

/// Gateway Jurnal berbasis file yang dipakai Task Master New.
///
/// Mendukung format Jurnal bulanan (`jurnal_YYYY_MM.json`) beserta file
/// template `jurnal_template.json`, dan tetap dapat membaca format master lama
/// `time_log.json` bila file baru belum pernah dibuat.
class FileJournalGateway implements JournalGateway {
  FileJournalGateway({
    required StorageService storageService,
    required Future<String> Function() baseDirProvider,
    Future<bool> Function()? encryptionEnabledProvider,
    Future<String?> Function()? passwordProvider,
    DateTime Function()? clock,
  }) : _baseDirProvider = baseDirProvider,
       _encryptionEnabledProvider =
           encryptionEnabledProvider ?? storageService.isEncryptionEnabled,
       _passwordProvider =
           passwordProvider ?? storageService.getEncryptionPassword,
       _clock = clock ?? DateTime.now;

  final Future<String> Function() _baseDirProvider;
  final Future<bool> Function() _encryptionEnabledProvider;
  final Future<String?> Function() _passwordProvider;
  final DateTime Function() _clock;

  Future<void> _operationQueue = Future<void>.value();

  @override
  Future<JournalLinkState> loadLinks() {
    return _enqueue(_loadLinks);
  }

  @override
  Future<JournalAdjustment?> addDuration({
    required String taskId,
    required DateTime at,
  }) {
    return _enqueue(() => _addDuration(taskId: taskId, at: at));
  }

  @override
  Future<void> subtractDuration({
    required JournalAdjustment adjustment,
    required DateTime at,
  }) {
    return _enqueue(() => _subtractDuration(adjustment: adjustment, at: at));
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<JournalLinkState> _loadLinks() async {
    final todayKey = _dateKey(_clock());
    final templateFile = await _templateFile();
    if (await templateFile.exists()) {
      final decoded = await _readJson(templateFile);
      final templateTasks = _tasksFromTemplate(decoded);
      final linkedTaskIds = _collectLinkedTaskIds(templateTasks);

      // Template bisa tertinggal dari log hari ini bila tautan baru diubah.
      // Hanya entri hari ini yang digabungkan agar tautan lama tidak menempel.
      final monthFile = await _monthFile(_clock());
      var todayMinutes = 0;
      if (await monthFile.exists()) {
        final logs = await _readLogs(monthFile);
        linkedTaskIds.addAll(
          _collectLinkedTaskIdsFromLogs(logs, dateKey: todayKey),
        );
        todayMinutes = _todayMinutesFromLogs(logs, dateKey: todayKey);
      }

      return JournalLinkState(
        linkedTaskIds: linkedTaskIds,
        incrementMinutes: _incrementMinutesFrom(decoded),
        todayMinutes: todayMinutes,
      );
    }

    final monthFile = await _monthFile(_clock());
    if (await monthFile.exists()) {
      final logs = await _readLogs(monthFile);
      return JournalLinkState(
        linkedTaskIds: _collectLinkedTaskIdsFromLogs(logs, dateKey: todayKey),
        todayMinutes: _todayMinutesFromLogs(logs, dateKey: todayKey),
      );
    }

    final oldMasterFile = await _oldMasterFile();
    if (await oldMasterFile.exists()) {
      final logs = await _readLogs(oldMasterFile);
      return JournalLinkState(
        linkedTaskIds: _collectLinkedTaskIdsFromLogs(logs, dateKey: todayKey),
        todayMinutes: _todayMinutesFromLogs(logs, dateKey: todayKey),
      );
    }

    return JournalLinkState.empty;
  }

  Future<JournalAdjustment?> _addDuration({
    required String taskId,
    required DateTime at,
  }) async {
    if (await _useOldMasterStorage(at)) {
      return _addDurationToOldMaster(taskId: taskId, at: at);
    }
    return _addDurationToMonthlyLogs(taskId: taskId, at: at);
  }

  Future<void> _subtractDuration({
    required JournalAdjustment adjustment,
    required DateTime at,
  }) async {
    if (await _useOldMasterStorage(at)) {
      await _subtractFromOldMaster(adjustment: adjustment, at: at);
      return;
    }
    await _subtractFromMonthlyLogs(adjustment: adjustment, at: at);
  }

  Future<JournalAdjustment?> _addDurationToMonthlyLogs({
    required String taskId,
    required DateTime at,
  }) async {
    final templateFile = await _templateFile();
    final monthFile = await _monthFile(at);

    var templateTasks = <dynamic>[];
    var incrementMinutes = defaultJournalIncrementMinutes;
    if (await templateFile.exists()) {
      final decoded = await _readJson(templateFile);
      templateTasks = _tasksFromTemplate(decoded);
      incrementMinutes = _incrementMinutesFrom(decoded);
    }

    return _applyDurationAdd(
      file: monthFile,
      logs: await _readLogsIfExists(monthFile),
      templateTasks: templateTasks,
      incrementMinutes: incrementMinutes,
      taskId: taskId,
      at: at,
    );
  }

  Future<JournalAdjustment?> _addDurationToOldMaster({
    required String taskId,
    required DateTime at,
  }) async {
    final oldMasterFile = await _oldMasterFile();
    final logs = await _readLogs(oldMasterFile);
    final templateTasks = logs.isEmpty || logs.last is! Map
        ? <dynamic>[]
        : _asList((logs.last as Map)['tasks']);

    return _applyDurationAdd(
      file: oldMasterFile,
      logs: logs,
      templateTasks: templateTasks,
      incrementMinutes: defaultJournalIncrementMinutes,
      taskId: taskId,
      at: at,
      linkedTask: _findLinkedTaskFromLogs(logs, taskId),
    );
  }

  Future<JournalAdjustment?> _applyDurationAdd({
    required File file,
    required List<dynamic> logs,
    required List<dynamic> templateTasks,
    required int incrementMinutes,
    required String taskId,
    required DateTime at,
    Map<String, dynamic>? linkedTask,
  }) async {
    final todayKey = _dateKey(at);
    var todayEntry = _findEntry(logs, todayKey);
    var todayTasks = todayEntry == null
        ? <dynamic>[]
        : _asList(todayEntry['tasks']);

    linkedTask ??=
        _findLinkedTask(templateTasks, taskId) ??
        _findLinkedTask(todayTasks, taskId);
    if (linkedTask == null) return null;

    final journalTaskId = _stringValue(linkedTask['id']);
    if (todayEntry == null) {
      todayEntry = <String, dynamic>{
        'tanggal': todayKey,
        'tasks': templateTasks.map(_cloneMap).toList(),
      };
      logs.add(todayEntry);
      todayTasks = _asList(todayEntry['tasks']);
    }

    final journalTask =
        _findTaskById(todayTasks, journalTaskId) ??
        _appendTask(todayTasks, linkedTask);
    final currentMinutes = _intValue(journalTask['durasi_menit']);
    journalTask['durasi_menit'] = currentMinutes + incrementMinutes;

    await _writeJson(file, logs);
    return JournalAdjustment(
      journalTaskId: journalTaskId,
      minutes: incrementMinutes,
    );
  }

  Future<void> _subtractFromMonthlyLogs({
    required JournalAdjustment adjustment,
    required DateTime at,
  }) async {
    final monthFile = await _monthFile(at);
    await _applyDurationSubtract(
      file: monthFile,
      logs: await _readLogsIfExists(monthFile),
      adjustment: adjustment,
      at: at,
    );
  }

  Future<void> _subtractFromOldMaster({
    required JournalAdjustment adjustment,
    required DateTime at,
  }) async {
    final oldMasterFile = await _oldMasterFile();
    await _applyDurationSubtract(
      file: oldMasterFile,
      logs: await _readLogs(oldMasterFile),
      adjustment: adjustment,
      at: at,
    );
  }

  Future<void> _applyDurationSubtract({
    required File file,
    required List<dynamic> logs,
    required JournalAdjustment adjustment,
    required DateTime at,
  }) async {
    final entry = _findEntry(logs, _dateKey(at));
    final journalTask = entry == null
        ? null
        : _findTaskById(_asList(entry['tasks']), adjustment.journalTaskId);

    if (journalTask == null) {
      throw JournalGatewayException(
        'Aktivitas Jurnal yang tertaut tidak ditemukan. '
        'Durasi Jurnal tidak dapat dikurangi secara otomatis.',
      );
    }

    final currentMinutes = _intValue(journalTask['durasi_menit']);
    final remainingMinutes = currentMinutes - adjustment.minutes;
    journalTask['durasi_menit'] = math.max(0, remainingMinutes);
    await _writeJson(file, logs);

    if (remainingMinutes < 0) {
      throw JournalGatewayException(
        'Durasi Jurnal lebih kecil dari yang ditambahkan increment. '
        'Hanya sebagian durasi yang dapat dikurangi.',
      );
    }
  }

  Future<bool> _useOldMasterStorage(DateTime at) async {
    final templateFile = await _templateFile();
    if (await templateFile.exists()) return false;

    final monthFile = await _monthFile(at);
    if (await monthFile.exists()) return false;

    final oldMasterFile = await _oldMasterFile();
    return oldMasterFile.exists();
  }

  Future<File> _templateFile() async {
    final directory = await _journalDirectory();
    return File('${directory.path}/jurnal_template.json');
  }

  Future<File> _monthFile(DateTime date) async {
    final directory = await _journalDirectory();
    final month = date.month.toString().padLeft(2, '0');
    return File('${directory.path}/jurnal_${date.year}_$month.json');
  }

  Future<File> _oldMasterFile() async {
    final directory = await _journalDirectory();
    return File('${directory.path}/time_log.json');
  }

  Future<Directory> _journalDirectory() async {
    final baseDir = await _baseDirProvider();
    final directory = Directory('$baseDir/jurnal_aktivitas');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Object?> _readJson(File file) async {
    final text = await _readText(file);
    try {
      return jsonDecode(text);
    } catch (error) {
      throw JournalGatewayException(
        'File Jurnal tidak dapat dibaca sebagai JSON. '
        'Durasi Jurnal tidak diubah.',
        cause: error,
      );
    }
  }

  Future<String> _readText(File file) async {
    final rawContent = await file.readAsString();
    if (_looksLikePlainJson(rawContent)) return rawContent;

    final encryptionEnabled = await _encryptionEnabledProvider();
    if (!encryptionEnabled) {
      throw JournalGatewayException(
        'File Jurnal tidak dapat dibaca sebagai JSON dan enkripsi nonaktif.',
      );
    }

    final password = await _passwordProvider();
    if (password == null || password.isEmpty) {
      throw JournalGatewayException(
        'File Jurnal terenkripsi. Masukkan PIN/kata sandi untuk membukanya.',
      );
    }

    try {
      return CryptoHelper.decrypt(rawContent, password);
    } catch (error) {
      throw JournalGatewayException(
        'Kata sandi salah atau file Jurnal korup. '
        'Durasi Jurnal tidak diubah.',
        cause: error,
      );
    }
  }

  Future<void> _writeJson(File file, Object value) async {
    var content = jsonEncode(value);
    final encryptionEnabled = await _encryptionEnabledProvider();
    if (encryptionEnabled) {
      final password = await _passwordProvider();
      if (password == null || password.isEmpty) {
        throw JournalGatewayException(
          'Enkripsi aktif tetapi kata sandi tidak tersedia. '
          'Durasi Jurnal tidak disimpan agar data tidak bocor.',
        );
      }
      content = CryptoHelper.encrypt(content, password);
    }

    final success = await AtomicWriteHelper.writeSafe(
      targetFile: file,
      content: content,
    );
    if (!success) {
      throw JournalGatewayException(
        'Gagal menulis file Jurnal secara aman. '
        'Durasi Jurnal tidak diubah; silakan coba lagi.',
      );
    }
  }

  Future<List<dynamic>> _readLogs(File file) async {
    final decoded = await _readJson(file);
    if (decoded is! List) {
      throw JournalGatewayException(
        'Struktur file Jurnal tidak valid. Durasi Jurnal tidak diubah.',
      );
    }
    return decoded;
  }

  Future<List<dynamic>> _readLogsIfExists(File file) async {
    if (!await file.exists()) return <dynamic>[];
    return _readLogs(file);
  }

  List<dynamic> _tasksFromTemplate(Object? decoded) {
    if (decoded is Map) {
      return _asList(decoded['tasks']);
    }
    if (decoded is List) return decoded;
    throw JournalGatewayException(
      'Struktur template Jurnal tidak valid. Durasi Jurnal tidak diubah.',
    );
  }

  int _incrementMinutesFrom(Object? decoded) {
    if (decoded is Map) {
      final settings = decoded['settings'];
      if (settings is Map) {
        final raw = settings['default_increment_minutes'];
        final value = raw is num
            ? raw.toInt()
            : int.tryParse(raw?.toString() ?? '');
        if (value != null && value > 0) return value;
      }
    }
    return defaultJournalIncrementMinutes;
  }

  Set<String> _collectLinkedTaskIds(List<dynamic> tasks) {
    final ids = <String>{};
    for (final task in tasks) {
      if (task is! Map) continue;
      final linked = task['linkedTaskIds'];
      if (linked is List) {
        for (final id in linked) {
          if (id is String && id.isNotEmpty) ids.add(id);
        }
      }
    }
    return ids;
  }

  Set<String> _collectLinkedTaskIdsFromLogs(
    List<dynamic> logs, {
    required String dateKey,
  }) {
    final ids = <String>{};
    for (final entry in logs) {
      if (entry is! Map || entry['tanggal'] != dateKey) continue;
      ids.addAll(_collectLinkedTaskIds(_asList(entry['tasks'])));
    }
    return ids;
  }

  int _todayMinutesFromLogs(List<dynamic> logs, {required String dateKey}) {
    final entry = _findEntry(logs, dateKey);
    if (entry == null) return 0;

    var total = 0;
    for (final task in _asList(entry['tasks'])) {
      if (task is! Map) continue;
      total += _intValue(task['durasi_menit']);
    }
    return total;
  }

  Map<String, dynamic>? _findLinkedTask(List<dynamic> tasks, String taskId) {
    for (final task in tasks) {
      if (task is! Map) continue;
      final linked = task['linkedTaskIds'];
      if (linked is List && linked.contains(taskId)) {
        return task.cast<String, dynamic>();
      }
    }
    return null;
  }

  Map<String, dynamic>? _findLinkedTaskFromLogs(
    List<dynamic> logs,
    String taskId,
  ) {
    for (final entry in logs.reversed) {
      if (entry is! Map) continue;
      final linked = _findLinkedTask(_asList(entry['tasks']), taskId);
      if (linked != null) return linked;
    }
    return null;
  }

  Map<String, dynamic>? _findEntry(List<dynamic> logs, String dateKey) {
    for (final entry in logs) {
      if (entry is Map && entry['tanggal'] == dateKey) {
        return entry.cast<String, dynamic>();
      }
    }
    return null;
  }

  Map<String, dynamic>? _findTaskById(List<dynamic> tasks, String taskId) {
    for (final task in tasks) {
      if (task is Map && _stringValue(task['id']) == taskId) {
        return task.cast<String, dynamic>();
      }
    }
    return null;
  }

  Map<String, dynamic> _appendTask(List<dynamic> tasks, Map task) {
    final clone = _cloneMap(task);
    clone['durasi_menit'] = 0;
    tasks.add(clone);
    return clone;
  }

  Map<String, dynamic> _cloneMap(Object? value) {
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _stringValue(Object? value) => value?.toString() ?? '';

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool _looksLikePlainJson(String content) {
    final trimmed = content.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}
