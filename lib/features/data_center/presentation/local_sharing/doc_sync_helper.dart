// lib/features/data_center/presentation/local_sharing/doc_sync_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';

class DocManifestItem {
  final String path;
  final int size;
  final int modified;

  DocManifestItem({
    required this.path,
    required this.size,
    required this.modified,
  });

  Map<String, dynamic> toJson() => {'p': path, 's': size, 'm': modified};

  factory DocManifestItem.fromJson(Map<String, dynamic> json) =>
      DocManifestItem(
        path: json['p'] ?? '',
        size: json['s'] ?? 0,
        modified: json['m'] ?? 0,
      );
}

class DocSyncHelper {
  static bool _isSyncDialogOpen = false;
  static ValueNotifier<String>? _currentStatusNotifier;

  // PERBAIKAN: Manajemen Dialog Mandiri yang Deterministik (Anti-Stuck)
  static void showSyncDialog({
    required BuildContext context,
    required String title,
    required ValueNotifier<String> statusNotifier,
    required bool isSending,
  }) {
    if (_isSyncDialogOpen) {
      _currentStatusNotifier = statusNotifier;
      return;
    }
    _isSyncDialogOpen = true;
    _currentStatusNotifier = statusNotifier;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) {
        final accentColor = isSending ? Colors.teal : Colors.indigo;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                          backgroundColor: accentColor.withOpacity(0.1),
                        ),
                      ),
                      Icon(
                        isSending
                            ? Icons.swap_vertical_circle_outlined
                            : Icons.cloud_download_rounded,
                        size: 40,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, status, child) {
                    return Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isSending ? 'PROSES MENGIRIM...' : 'PROSES MENERIMA...',
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isSyncDialogOpen = false;
      _currentStatusNotifier = null;
    });
  }

  static void updateStatus(String status) {
    if (_currentStatusNotifier != null) {
      _currentStatusNotifier!.value = status;
    }
  }

  static void closeSyncDialog(BuildContext context) {
    if (_isSyncDialogOpen && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isSyncDialogOpen = false;
      _currentStatusNotifier = null;
    }
  }

  static Future<List<DocManifestItem>> createManifest(String baseDir) async {
    final Directory docDir = Directory('$baseDir/my_documents');
    if (!await docDir.exists()) return [];

    List<DocManifestItem> list = [];
    final List<FileSystemEntity> entities = docDir.listSync(recursive: true);

    for (var entity in entities) {
      if (entity is File) {
        String relPath = entity.path
            .substring(docDir.path.length + 1)
            .replaceAll('\\', '/');
        list.add(
          DocManifestItem(
            path: relPath,
            size: entity.lengthSync(),
            modified: entity.lastModifiedSync().millisecondsSinceEpoch,
          ),
        );
      }
    }
    return list;
  }

  static Map<String, List<String>> reconcile({
    required List<DocManifestItem> senderManifest,
    required List<DocManifestItem> receiverManifest,
  }) {
    Map<String, DocManifestItem> senderMap = {
      for (var item in senderManifest) item.path: item,
    };
    Map<String, DocManifestItem> receiverMap = {
      for (var item in receiverManifest) item.path: item,
    };

    List<String> toDelete = [];
    List<String> toRequest = [];

    for (var recPath in receiverMap.keys) {
      if (!senderMap.containsKey(recPath)) toDelete.add(recPath);
    }

    for (var senderItem in senderManifest) {
      final recItem = receiverMap[senderItem.path];
      if (recItem == null) {
        toRequest.add(senderItem.path);
      } else {
        if (recItem.size != senderItem.size ||
            recItem.modified != senderItem.modified) {
          toRequest.add(senderItem.path);
        }
      }
    }
    return {'delete': toDelete, 'request': toRequest};
  }

  static Future<void> deleteLocalFiles(
    String baseDir,
    List<String> relPaths,
  ) async {
    final Directory docDir = Directory('$baseDir/my_documents');
    for (var path in relPaths) {
      final file = File('${docDir.path}/$path');
      if (await file.exists()) await file.delete();
    }
  }

  static Future<Map<String, dynamic>> packageRequestedFiles(
    String baseDir,
    List<String> requestedPaths,
  ) async {
    final Directory docDir = Directory('$baseDir/my_documents');
    final Archive archive = Archive();
    Map<String, int> timestamps = {};

    for (var relPath in requestedPaths) {
      final file = File('${docDir.path}/$relPath');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(relPath, bytes.length, bytes));
        timestamps[relPath] = file.lastModifiedSync().millisecondsSinceEpoch;
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    return {
      'zip_base64': zipBytes != null ? base64Encode(zipBytes) : "",
      'timestamps': timestamps,
    };
  }

  static Future<int> extractAndApplyDelta({
    required String baseDir,
    required String zipBase64,
    required Map<String, dynamic> timestamps,
  }) async {
    if (zipBase64.isEmpty) return 0;

    final Directory docDir = Directory('$baseDir/my_documents');
    if (!await docDir.exists()) await docDir.create(recursive: true);

    final bytes = base64Decode(zipBase64);
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    int count = 0;

    for (ArchiveFile file in archive) {
      if (file.isFile) {
        final outFile = File('${docDir.path}/${file.name}');
        if (!await outFile.parent.exists()) {
          await outFile.parent.create(recursive: true);
        }
        await outFile.writeAsBytes(file.content as List<int>, flush: true);

        if (timestamps.containsKey(file.name)) {
          outFile.setLastModifiedSync(
            DateTime.fromMillisecondsSinceEpoch(timestamps[file.name]),
          );
        }
        count++;
      }
    }
    return count;
  }

  // PUSAT PENANGANAN PESAN WEBSOCKET MIRRORING
  static Future<bool> handleDocSyncStream({
    required String pesanMasuk,
    required dynamic socketSink,
    required BuildContext context,
    required StorageService storageService,
    Function(bool)? onLoadingStatusChanged,
  }) async {
    try {
      Map<String, dynamic> data = jsonDecode(pesanMasuk);
      String tipe = data['tipe_pesan'] ?? '';

      if (!tipe.startsWith('doc_sync_')) return false;

      if (tipe == 'doc_sync_init') {
        closeSyncDialog(context);
        final statusNotifier = ValueNotifier<String>(
          'Memeriksa katalog dokumen masuk...',
        );

        if (context.mounted) {
          showSyncDialog(
            context: context,
            title: 'Menerima Cermin Dokumen',
            statusNotifier: statusNotifier,
            isSending: false,
          );
        }

        List<dynamic> rawSender = data['manifest'] ?? [];
        List<DocManifestItem> senderManifest = rawSender
            .map((x) => DocManifestItem.fromJson(x))
            .toList();

        String currentDir = await storageService.getBaseDirSetting();
        List<DocManifestItem> localManifest = await createManifest(currentDir);

        statusNotifier.value = 'Melakukan sensus komparasi berkas...';

        final rekonsiliasi = reconcile(
          senderManifest: senderManifest,
          receiverManifest: localManifest,
        );

        List<String> toDelete = rekonsiliasi['delete']!;
        List<String> toRequest = rekonsiliasi['request']!;

        if (toDelete.isNotEmpty && localManifest.isNotEmpty) {
          double deleteRatio = toDelete.length / localManifest.length;
          if (deleteRatio >= 0.30 || senderManifest.isEmpty) {
            closeSyncDialog(context);
            if (!context.mounted) return true;

            bool? confirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('  Peringatan Kritis!'),
                  ],
                ),
                content: Text(
                  'Proses cermin ini akan MENGHAPUS PERMANEN ${toDelete.length} dokumen lokal (${(deleteRatio * 100).toStringAsFixed(0)}% total dokumen Anda) karena pengirim tidak memilikinya.\n\nApakah Anda yakin katalog pengirim sudah benar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (onLoadingStatusChanged != null)
                        onLoadingStatusChanged(false);
                      Navigator.pop(ctx, false);
                    },
                    child: const Text('Batal & Tolak'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Ya, Hapus & Samakan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed != true) {
              if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);
              socketSink.add(
                jsonEncode({
                  'tipe_pesan': 'doc_sync_abort',
                  'reason':
                      'Dibatalkan oleh pengguna target karena proteksi massal.',
                }),
              );
              return true;
            }

            if (context.mounted) {
              showSyncDialog(
                context: context,
                title: 'Menerima Cermin Dokumen',
                statusNotifier: statusNotifier,
                isSending: false,
              );
            }
          }
        }

        if (toDelete.isNotEmpty) {
          statusNotifier.value = 'Menghapus ${toDelete.length} berkas usang...';
          await deleteLocalFiles(currentDir, toDelete);
        }

        if (toRequest.isEmpty) {
          closeSyncDialog(
            context,
          ); // Langsung tutup di sisi Klien karena identik
          if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);

          socketSink.add(
            jsonEncode({
              'tipe_pesan': 'doc_sync_done',
              'msg': 'Sempurna! Seluruh dokumen sudah identik.',
            }),
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sensus selesai: Dokumen sudah identik dengan pengirim!',
                ),
                backgroundColor: Colors.teal,
              ),
            );
          }
        } else {
          statusNotifier.value = 'Meminta ${toRequest.length} berkas delta...';
          socketSink.add(
            jsonEncode({
              'tipe_pesan': 'doc_sync_request_delta',
              'requested_files': toRequest,
            }),
          );
        }
        return true;
      } else if (tipe == 'doc_sync_request_delta') {
        List<dynamic> reqFiles = data['requested_files'] ?? [];
        List<String> toSend = reqFiles.map((e) => e.toString()).toList();

        if (_isSyncDialogOpen) {
          updateStatus('Membungkus ${toSend.length} dokumen...');
        } else {
          final statusNotifier = ValueNotifier<String>(
            'Membungkus ${toSend.length} dokumen...',
          );
          if (context.mounted) {
            showSyncDialog(
              context: context,
              title: 'Mengirim Paket Delta',
              statusNotifier: statusNotifier,
              isSending: true,
            );
          }
        }

        String currentDir = await storageService.getBaseDirSetting();
        final deltaPackage = await packageRequestedFiles(currentDir, toSend);

        updateStatus('Menyemburkan data nirkabel...');

        socketSink.add(
          jsonEncode({
            'tipe_pesan': 'doc_sync_payload',
            'zip_base64': deltaPackage['zip_base64'],
            'timestamps': deltaPackage['timestamps'],
          }),
        );
        if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);
        return true;
      } else if (tipe == 'doc_sync_payload') {
        if (_isSyncDialogOpen) {
          updateStatus('Menerapkan berkas delta...');
        } else {
          final statusNotifier = ValueNotifier<String>(
            'Menerapkan berkas delta...',
          );
          if (context.mounted) {
            showSyncDialog(
              context: context,
              title: 'Menerapkan Berkas Delta',
              statusNotifier: statusNotifier,
              isSending: false,
            );
          }
        }

        String currentDir = await storageService.getBaseDirSetting();
        int count = await extractAndApplyDelta(
          baseDir: currentDir,
          zipBase64: data['zip_base64'] ?? '',
          timestamps: data['timestamps'] ?? {},
        );

        closeSyncDialog(context); // Klien selesai menerapkan berkas delta!
        if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);

        socketSink.add(
          jsonEncode({
            'tipe_pesan': 'doc_sync_done',
            'msg': 'Berhasil memperbarui $count dokumen baru!',
          }),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '  Sinkronisasi cermin selesai! ($count berkas diperbarui)',
              ),
              backgroundColor: Colors.teal,
            ),
          );
        }
        return true;
      } else if (tipe == 'doc_sync_done') {
        closeSyncDialog(context); // Pengirim menerima balasan selesai!
        if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('  ${data['msg']}'),
              backgroundColor: Colors.teal,
            ),
          );
        }
        return true;
      } else if (tipe == 'doc_sync_abort') {
        closeSyncDialog(context);
        if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('  Sinkronisasi dibatalkan: ${data['reason']}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      closeSyncDialog(context);
      if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);
      debugPrint("DocSyncHelper Error: $e");
      return false;
    }
  }
}
