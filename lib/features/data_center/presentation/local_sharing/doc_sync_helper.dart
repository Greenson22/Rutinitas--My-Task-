// lib/features/data_center/presentation/local_sharing/doc_sync_helper.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  // Variabel untuk melacak data biner file yang akan masuk (Streaming State)
  static Map<String, dynamic>? _nextIncomingFileMeta;
  static bool _isWaitingForBinary = false;

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

  // METODE BARU: Mengirim Berkas Biner Satu per Satu (Anti Force Close)
  static Future<void> streamRequestedFiles({
    required String baseDir,
    required List<String> requestedPaths,
    required dynamic socketSink,
  }) async {
    final Directory docDir = Directory('$baseDir/my_documents');

    for (int i = 0; i < requestedPaths.length; i++) {
      final String relPath = requestedPaths[i];
      final file = File('${docDir.path}/$relPath');

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final int timestamp = file.lastModifiedSync().millisecondsSinceEpoch;

        updateStatus('Mengirim [${i + 1}/${requestedPaths.length}]\n$relPath');

        // 1. Kirim Metadata Teks
        socketSink.add(
          jsonEncode({
            'tipe_pesan': 'doc_sync_file_chunk_init',
            'path': relPath,
            'timestamp': timestamp,
            'is_last': i == requestedPaths.length - 1,
          }),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // 2. Kirim Biner Asli
        socketSink.add(bytes);

        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        // Jika file hilang, amankan proses dengan dummy data jika itu adalah file terakhir
        if (i == requestedPaths.length - 1) {
          socketSink.add(
            jsonEncode({
              'tipe_pesan': 'doc_sync_file_chunk_init',
              'path': 'EOF_DUMMY',
              'timestamp': 0,
              'is_last': true,
            }),
          );
          await Future.delayed(const Duration(milliseconds: 50));
          socketSink.add(<int>[]);
        }
      }
    }
  }

  // PUSAT PENANGANAN PESAN WEBSOCKET MIRRORING
  static Future<bool> handleDocSyncStream({
    required dynamic pesanMasuk, // PERBAIKAN: Ubah menjadi dynamic
    required dynamic socketSink,
    required BuildContext context,
    required StorageService storageService,
    Function(bool)? onLoadingStatusChanged,
  }) async {
    try {
      String currentDir = await storageService.getBaseDirSetting();

      // 1. TANGANI JIKA PESAN MASUK ADALAH DATA BINER
      if (pesanMasuk is List<int> || pesanMasuk is Uint8List) {
        if (_isWaitingForBinary && _nextIncomingFileMeta != null) {
          final String relPath = _nextIncomingFileMeta!['path'];
          final int timestamp = _nextIncomingFileMeta!['timestamp'];
          final bool isLast = _nextIncomingFileMeta!['is_last'];

          if (relPath != 'EOF_DUMMY' && pesanMasuk.isNotEmpty) {
            final outFile = File('$currentDir/my_documents/$relPath');
            if (!await outFile.parent.exists()) {
              await outFile.parent.create(recursive: true);
            }

            // Tulis langsung ke penyimpanan tanpa singgah memori RAM berlebih
            await outFile.writeAsBytes(pesanMasuk as List<int>, flush: true);
            outFile.setLastModifiedSync(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
            );
          }

          _isWaitingForBinary = false;

          if (isLast) {
            closeSyncDialog(context);
            if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);

            socketSink.add(
              jsonEncode({
                'tipe_pesan': 'doc_sync_done',
                'msg': 'Sinkronisasi cermin selesai dengan aman!',
              }),
            );
          }
          return true;
        }
        return false;
      }

      // 2. TANGANI JIKA PESAN MASUK ADALAH TEKS JSON
      Map<String, dynamic> data = jsonDecode(pesanMasuk.toString());
      String tipe = data['tipe_pesan'] ?? '';

      if (!tipe.startsWith('doc_sync_')) return false;

      // Terima sinyal awal sebelum data biner masuk
      if (tipe == 'doc_sync_file_chunk_init') {
        _nextIncomingFileMeta = data;
        _isWaitingForBinary = true;
        updateStatus('Menerima berkas:\n${data['path']}');
        return true;
      }

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
          closeSyncDialog(context);
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
          updateStatus('Mempersiapkan ${toSend.length} dokumen...');
        } else {
          final statusNotifier = ValueNotifier<String>(
            'Mempersiapkan ${toSend.length} dokumen...',
          );
          if (context.mounted) {
            showSyncDialog(
              context: context,
              title: 'Mengirim Antrean Dokumen',
              statusNotifier: statusNotifier,
              isSending: true,
            );
          }
        }

        // PERBAIKAN: Ganti proses ZIP raksasa dengan Streaming
        await streamRequestedFiles(
          baseDir: currentDir,
          requestedPaths: toSend,
          socketSink: socketSink,
        );

        if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);
        return true;
      } else if (tipe == 'doc_sync_done') {
        closeSyncDialog(context);
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
      _isWaitingForBinary = false;
      closeSyncDialog(context);
      if (onLoadingStatusChanged != null) onLoadingStatusChanged(false);
      debugPrint("DocSyncHelper Error: $e");
      return false;
    }
  }
}
