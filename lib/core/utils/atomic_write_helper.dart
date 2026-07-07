// lib/core/utils/atomic_write_helper.dart
import 'dart:io';
import 'package:flutter/material.dart';

class AtomicWriteHelper {
  /// Melakukan penulisan file secara aman untuk mencegah data korup (.tmp -> .json)
  static Future<bool> writeSafe({
    required File targetFile,
    required String content,
  }) async {
    String tempPath =
        '${targetFile.path}_${DateTime.now().microsecondsSinceEpoch}.tmp';
    File tempFile = File(tempPath);

    try {
      // 1. Tulis data ke file temporary terlebih dahulu
      await tempFile.writeAsString(content, flush: true);

      // 2. Pastikan file temporary benar-benar berhasil dibuat dan terisi
      if (await tempFile.exists()) {
        // 3. Hapus file asli lama jika ada (menghindari permission error pada OS tertentu)
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        // 4. Ubah nama file .tmp menjadi nama file target (.json)
        await tempFile.rename(targetFile.path);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Atomic Write Error pada file ${targetFile.path}: $e");

      // Fail-safe: Bersihkan file temp jika proses gagal di tengah jalan
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return false;
    }
  }
}
