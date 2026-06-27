import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';

class DocManifestItem {
  final String
  path; // Path relatif dari my_documents/, misal: "group_1.json" atau "folder/skripsi.pdf"
  final int size;
  final int modified; // MillisecondsSinceEpoch (Sidik jari file)

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
  // FASE 1: Memindai seluruh folder my_documents beserta sub-foldernya
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

  // FASE 3: Mesin Rekonsiliasi (Sensus Pihak Penerima)
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

    List<String> toDelete = []; // Ember B
    List<String> toRequest = []; // Ember A

    // Cek Ember B: Ada di Penerima, tapi TIDAK ADA di Pengirim
    for (var recPath in receiverMap.keys) {
      if (!senderMap.containsKey(recPath)) toDelete.add(recPath);
    }

    // Cek Ember A: Ada di Pengirim, butuh dikirim karena tidak ada di Lokal ATAU isi berubah (Jebakan #1)
    for (var senderItem in senderManifest) {
      final recItem = receiverMap[senderItem.path];
      if (recItem == null) {
        toRequest.add(senderItem.path); // File baru
      } else {
        // Jebakan #1 Fix: Jika ukuran beda ATAU timestamp pengirim berbeda -> Timpa
        if (recItem.size != senderItem.size ||
            recItem.modified != senderItem.modified) {
          toRequest.add(senderItem.path);
        }
      }
    }

    return {'delete': toDelete, 'request': toRequest};
  }

  // Menghapus berkas lokal di Ember B
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

  // Membungkus berkas yang diminta (Ember A) ke ZIP Base64 beserta kamus Timestamps aslinya
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

  // Mengekstrak paket masuk & menerapkan Jebakan #1 fix (Menyamakan timestamp persis dengan pengirim)
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
        if (!await outFile.parent.exists())
          await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);

        // KUNCI JEBAKAN #1: Samakan sidik jari waktu lokal dengan server pengirim
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

  // PUSAT PENANGANI PESAN WEBSOCKET (Dipakai bersama oleh Server & Client)
  static Future<bool> handleDocSyncStream({
    required String pesanMasuk,
    required dynamic socketSink,
    required BuildContext context,
    required StorageService storageService,
    required Function(
      BuildContext,
      String,
      ValueNotifier<String>,
      bool,
      Function(BuildContext),
    )
    showProgressDialog,
  }) async {
    try {
      Map<String, dynamic> data = jsonDecode(pesanMasuk);
      String tipe = data['tipe_pesan'] ?? '';

      if (!tipe.startsWith('doc_sync_'))
        return false; // Bukan pesan cermin dokumen

      if (tipe == 'doc_sync_init') {
        // PERAN: KITA ADALAH PENERIMA
        BuildContext? progCtx;
        final statusNotifier = ValueNotifier<String>(
          'Memeriksa katalog dokumen masuk...',
        );

        if (context.mounted) {
          showProgressDialog(
            context,
            'Menerima Cermin Dokumen',
            statusNotifier,
            false,
            (c) => progCtx = c,
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

        // JEBAKAN #2 GUARD: Proteksi Penghapusan Masal Ekstrem (>30%)
        if (toDelete.isNotEmpty && localManifest.isNotEmpty) {
          double deleteRatio = toDelete.length / localManifest.length;
          if (deleteRatio >= 0.30 || senderManifest.isEmpty) {
            if (progCtx != null && progCtx!.mounted) Navigator.pop(progCtx!);

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
                    Text('⚠️ Peringatan Kritis!'),
                  ],
                ),
                content: Text(
                  'Proses cermin ini akan MENGHAPUS PERMANEN ${toDelete.length} dokumen lokal (${(deleteRatio * 100).toStringAsFixed(0)}% total dokumen Anda) karena pengirim tidak memilikinya.\n\nApakah Anda yakin katalog pengirim sudah benar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
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
              socketSink.add(
                jsonEncode({
                  'tipe_pesan': 'doc_sync_abort',
                  'reason': 'Dibatalkan oleh pengguna target.',
                }),
              );
              return true;
            }

            if (context.mounted) {
              showProgressDialog(
                context,
                'Menerima Cermin Dokumen',
                statusNotifier,
                false,
                (c) => progCtx = c,
              );
            }
          }
        }

        if (toDelete.isNotEmpty) {
          statusNotifier.value = 'Menghapus ${toDelete.length} berkas usang...';
          await deleteLocalFiles(currentDir, toDelete);
        }

        if (toRequest.isEmpty) {
          if (progCtx != null && progCtx!.mounted) Navigator.pop(progCtx!);
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
        // PERAN: KITA ADALAH PENGIRIM (Diminta mengirim berkas Delta)
        List<dynamic> reqFiles = data['requested_files'] ?? [];
        List<String> toSend = reqFiles.map((e) => e.toString()).toList();
        BuildContext? deltaCtx;
        final statusNotifier = ValueNotifier<String>(
          'Membungkus ${toSend.length} dokumen...',
        );

        if (context.mounted) {
          showProgressDialog(
            context,
            'Mengirim Paket Delta',
            statusNotifier,
            true,
            (c) => deltaCtx = c,
          );
        }

        String currentDir = await storageService.getBaseDirSetting();
        final deltaPackage = await packageRequestedFiles(currentDir, toSend);

        statusNotifier.value = 'Menyemburkan data nirkabel...';
        socketSink.add(
          jsonEncode({
            'tipe_pesan': 'doc_sync_payload',
            'zip_base64': deltaPackage['zip_base64'],
            'timestamps': deltaPackage['timestamps'],
          }),
        );

        if (deltaCtx != null && deltaCtx!.mounted) Navigator.pop(deltaCtx!);
        return true;
      } else if (tipe == 'doc_sync_payload') {
        // PERAN: KITA ADALAH PENERIMA (Paket Delta tiba)
        BuildContext? applyCtx;
        final statusNotifier = ValueNotifier<String>(
          'Menerima berkas delta...',
        );

        if (context.mounted) {
          showProgressDialog(
            context,
            'Menerapkan Berkas Delta',
            statusNotifier,
            false,
            (c) => applyCtx = c,
          );
        }

        String currentDir = await storageService.getBaseDirSetting();
        int count = await extractAndApplyDelta(
          baseDir: currentDir,
          zipBase64: data['zip_base64'] ?? '',
          timestamps: data['timestamps'] ?? {},
        );

        if (applyCtx != null && applyCtx!.mounted) Navigator.pop(applyCtx!);

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
                '🪞 Sinkronisasi cermin selesai! ($count berkas diperbarui)',
              ),
              backgroundColor: Colors.teal,
            ),
          );
        }
        return true;
      } else if (tipe == 'doc_sync_done') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🪞 ${data['msg']}'),
              backgroundColor: Colors.teal,
            ),
          );
        }
        return true;
      } else if (tipe == 'doc_sync_abort') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Sinkronisasi dibatalkan: ${data['reason']}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("DocSyncHelper Error: $e");
      return false;
    }
  }
}
