import 'package:rutinitasku/core/services/storage_service.dart';

import '../../domain/repositories/journal_gateway.dart';
import '../gateways/file_journal_gateway.dart';

/// Membuat gateway Jurnal default yang memakai folder, enkripsi, dan atomic
/// write yang sama dengan fitur Jurnal.
JournalGateway createJournalGateway({
  StorageService? storageService,
  DateTime Function()? clock,
}) {
  final storage = storageService ?? StorageService();
  return FileJournalGateway(
    storageService: storage,
    baseDirProvider: storage.getBaseDirSetting,
    encryptionEnabledProvider: storage.isEncryptionEnabled,
    passwordProvider: storage.getEncryptionPassword,
    clock: clock,
  );
}
