// lib/core/presentation/widgets/task_master_entry.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../features/task_master/presentation/screens/task_master_screen.dart';
import '../../../features/task_master_new/domain/repositories/journal_gateway.dart';
import '../../../features/task_master_new/domain/repositories/task_repository.dart';
import '../../../features/task_master_new/presentation/screens/task_master_screen.dart';
import '../../config/task_master_rollout.dart';
import '../../services/storage_service.dart';
import '../../utils/crypto_helper.dart';

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
    this.storageService,
    this.onPromoDecision,
    this.isSchemaV2Checker,
    this.legacyBuilder,
  });

  final TaskRepository? repository;
  final JournalGateway? journalGateway;
  final DateTime Function()? clock;
  final StorageService? storageService;
  final void Function(bool activated)? onPromoDecision;
  final Future<bool> Function()? isSchemaV2Checker;
  final WidgetBuilder? legacyBuilder;

  @override
  State<TaskMasterEntry> createState() => _TaskMasterEntryState();
}

class _TaskMasterEntryState extends State<TaskMasterEntry> {
  bool? _useNewModule;
  bool _promoChecked = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final useNew = await getTaskMasterUseNewModule(useCache: true);
    if (!mounted) return;

    setState(() {
      _useNewModule = useNew;
    });

    if (!useNew && !_promoChecked) {
      _promoChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowPromo();
      });
    }
  }

  Future<void> _checkAndShowPromo() async {
    if (!mounted) return;

    final seenPromo = await getSeenTaskMasterNewPromo(useCache: true);
    if (seenPromo) return;

    final isV2 = widget.isSchemaV2Checker != null
        ? await widget.isSchemaV2Checker!()
        : await _isDataFileSchemaV2();
    if (!isV2 || !mounted) return;

    _showPromoDialog();
  }

  Future<bool> _isDataFileSchemaV2() async {
    try {
      final storage = widget.storageService ?? StorageService();
      final baseDir = await storage.getBaseDirSetting();
      final targetFile = await storage.getTargetJsonFile(baseDir, createDirectory: false);
      if (!await targetFile.exists()) {
        return false;
      }

      String content = await targetFile.readAsString();
      final isEncrypted = await storage.isEncryptionEnabled();
      final password = await storage.getEncryptionPassword();
      if (isEncrypted && password != null && content.contains(':')) {
        try {
          content = CryptoHelper.decrypt(content, password);
        } catch (_) {
          return false;
        }
      }

      final dynamic decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic> && decoded['schemaVersion'] == 2) {
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  void _showPromoDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Aktifkan Task Master New?'),
          content: const Text(
            'Anda pernah memakai Task Master New. '
            'Aktifkan kembali untuk menikmati fitur terbaru dan riwayat yang tersimpan?',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await setSeenTaskMasterNewPromo(true);
                widget.onPromoDecision?.call(false);
              },
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await setSeenTaskMasterNewPromo(true);
                await setTaskMasterUseNewModule(true);
                widget.onPromoDecision?.call(true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Task Master New diaktifkan. Silakan mulai ulang aplikasi untuk menerapkan perubahan.',
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text('Aktifkan Sekarang'),
            ),
          ],
        );
      },
    );
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

    if (widget.legacyBuilder != null) {
      return widget.legacyBuilder!(context);
    }

    return const HomeScreen();
  }
}
