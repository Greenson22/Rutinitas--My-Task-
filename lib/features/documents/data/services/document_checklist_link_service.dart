import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_screen/controllers/daily_controller.dart';

/// Layanan propagasi tautan berkas My Documents pada item My Checklist.
///
/// Menggunakan [DailyController] agar pembacaan dan penulisan tetap melewati
/// jalur penyimpanan resmi checklist (termasuk enkripsi dan atomic write).
class DocumentChecklistLinkService {
  final DailyController _dailyController;

  DocumentChecklistLinkService({DailyController? dailyController})
    : _dailyController = dailyController ?? DailyController();

  /// Memperbarui tautan berkas saat berkas di-rename atau dipindah.
  Future<int> updateLinkPath(
    String groupId,
    String oldRelativePath,
    String newRelativePath,
    String newName, {
    String? newGroupId,
  }) async {
    return _mutateAllItems((item) {
      if (item.linkedDocumentGroupId == groupId &&
          item.linkedDocumentRelativePath == oldRelativePath) {
        item.linkedDocumentGroupId = newGroupId ?? groupId;
        item.linkedDocumentRelativePath = newRelativePath;
        item.linkedDocumentName = newName;
        return true;
      }
      return false;
    });
  }

  /// Memperbarui prefix path tautan saat folder di-rename atau dipindah.
  Future<int> updateFolderLinkPrefix(
    String groupId,
    String oldPrefix,
    String newPrefix,
  ) async {
    final normalizedOld = oldPrefix.endsWith('/') ? oldPrefix : '$oldPrefix/';
    final normalizedNew = newPrefix.endsWith('/') ? newPrefix : '$newPrefix/';
    return _mutateAllItems((item) {
      if (item.linkedDocumentGroupId == groupId &&
          item.linkedDocumentRelativePath != null &&
          item.linkedDocumentRelativePath!.startsWith(normalizedOld)) {
        final suffix = item.linkedDocumentRelativePath!.substring(
          normalizedOld.length,
        );
        item.linkedDocumentRelativePath = '$normalizedNew$suffix';
        return true;
      }
      return false;
    });
  }

  /// Melepas semua tautan di bawah [relativePathPrefix] (saat folder dihapus).
  Future<int> clearLinksFor(String groupId, String relativePathPrefix) async {
    final normalizedPrefix = relativePathPrefix.endsWith('/')
        ? relativePathPrefix
        : '$relativePathPrefix/';
    return _mutateAllItems((item) {
      if (item.linkedDocumentGroupId == groupId &&
          item.linkedDocumentRelativePath != null &&
          (item.linkedDocumentRelativePath == relativePathPrefix ||
              item.linkedDocumentRelativePath!.startsWith(normalizedPrefix))) {
        _clearItemLink(item);
        return true;
      }
      return false;
    });
  }

  /// Melepas tautan untuk satu berkas (saat berkas dihapus).
  Future<int> clearLinkForItem(String groupId, String relativePath) async {
    return _mutateAllItems((item) {
      if (item.linkedDocumentGroupId == groupId &&
          item.linkedDocumentRelativePath == relativePath) {
        _clearItemLink(item);
        return true;
      }
      return false;
    });
  }

  /// Melepas semua tautan yang menunjuk ke [groupId] (saat group dihapus).
  Future<int> clearLinksForGroup(String groupId) async {
    return _mutateAllItems((item) {
      if (item.linkedDocumentGroupId == groupId) {
        _clearItemLink(item);
        return true;
      }
      return false;
    });
  }

  void _clearItemLink(SubSubjectItem item) {
    item.linkedDocumentGroupId = null;
    item.linkedDocumentRelativePath = null;
    item.linkedDocumentName = null;
  }

  Future<int> _mutateAllItems(bool Function(SubSubjectItem item) mutator) async {
    await _dailyController.loadGroupsData(showLoading: false);
    int changedCount = 0;

    for (final group in _dailyController.allGroupRaw) {
      bool groupChanged = false;
      for (final section in group.allList) {
        for (final subject in section.items) {
          for (final item in subject.subMateri) {
            final count = _visitItem(item, mutator);
            if (count > 0) {
              changedCount += count;
              groupChanged = true;
            }
          }
        }
      }
      if (groupChanged) {
        await _dailyController.saveGroupDataToFile(group);
      }
    }

    return changedCount;
  }

  int _visitItem(
    SubSubjectItem item,
    bool Function(SubSubjectItem item) mutator,
  ) {
    int count = 0;
    if (mutator(item)) count++;
    for (final child in item.subMateri) {
      count += _visitItem(child, mutator);
    }
    return count;
  }
}
