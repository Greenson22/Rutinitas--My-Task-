import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/crypto_helper.dart';

/// Ambang ukuran teks (dalam karakter) sebelum pekerjaan CPU dipindahkan ke
/// isolate latar. Payload kecil diproses langsung agar test dan operasi rutin
/// tidak membayar biaya pembuatan isolate.
const int backgroundOffloadThresholdChars = 16 * 1024;

/// Jumlah tugas minimum sebelum JSON Task Master diproses di isolate latar.
const int backgroundOffloadTaskThreshold = 50;

/// Jumlah entri riwayat minimum sebelum JSON diproses di isolate latar.
///
/// Riwayat dapat membuat payload besar walau jumlah tugasnya sedikit, sehingga
/// keputusan offload tidak boleh hanya melihat jumlah tugas.
const int backgroundOffloadHistoryEntryThreshold = 200;

/// Konversi JSON Task Master yang dapat dijalankan di isolate latar.
///
/// Data layer memakai kontrak ini agar pemuatan dan penyimpanan data besar
/// tidak memblokir frame render. Implementasi dapat diganti pada test tanpa
/// menyentuh isolate.
abstract interface class TaskJsonCodec {
  Future<Map<String, dynamic>> decodeMap(String content);

  /// Mengubah [value] menjadi teks JSON satu baris untuk penyimpanan.
  Future<String> encode(Object? value);

  /// Mengubah [value] menjadi JSON terindentasi untuk editor Advanced.
  Future<String> encodePretty(Object? value);
}

/// Implementasi yang selalu berjalan di isolate pemanggil.
///
/// Berguna untuk test dan untuk pemakaian kecil yang tidak membutuhkan
/// perpindahan isolate.
class InlineTaskJsonCodec implements TaskJsonCodec {
  const InlineTaskJsonCodec();

  @override
  Future<Map<String, dynamic>> decodeMap(String content) async {
    return _formattedMap(jsonDecode(content));
  }

  @override
  Future<String> encode(Object? value) async => jsonEncode(value);

  @override
  Future<String> encodePretty(Object? value) async {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}

/// Implementasi produksi: payload besar diproses dengan `compute`.
///
/// `compute` memakai isolate pada Android, Linux, Windows, dan macOS, serta
/// berjalan inline pada platform web. Dengan begitu event loop UI tetap bebas
/// saat file Task Master berisi ribuan tugas.
class IsolateTaskJsonCodec implements TaskJsonCodec {
  const IsolateTaskJsonCodec({
    this.offloadThresholdChars = backgroundOffloadThresholdChars,
    this.offloadTaskThreshold = backgroundOffloadTaskThreshold,
    this.offloadHistoryEntryThreshold = backgroundOffloadHistoryEntryThreshold,
  });

  final int offloadThresholdChars;
  final int offloadTaskThreshold;
  final int offloadHistoryEntryThreshold;

  @override
  Future<Map<String, dynamic>> decodeMap(String content) {
    if (content.length < offloadThresholdChars) {
      return const InlineTaskJsonCodec().decodeMap(content);
    }
    return compute(_decodeJsonInBackground, content);
  }

  @override
  Future<String> encode(Object? value) {
    if (!_shouldOffload(value)) {
      return Future<String>.value(jsonEncode(value));
    }
    return compute(_encodeJsonInBackground, value);
  }

  @override
  Future<String> encodePretty(Object? value) {
    if (!_shouldOffload(value)) {
      return const InlineTaskJsonCodec().encodePretty(value);
    }
    return compute(_prettyEncodeJsonInBackground, value);
  }

  bool _shouldOffload(Object? value) {
    if (value is! Map) return false;
    final categories = value['categories'];
    if (categories is! List) return false;

    var tasks = 0;
    var historyEntries = 0;
    for (final category in categories) {
      if (category is! Map) continue;
      final categoryTasks = category['tasks'];
      if (categoryTasks is! List) continue;
      tasks += categoryTasks.length;
      for (final task in categoryTasks) {
        if (task is! Map) continue;
        final history = task['history'];
        if (history is Map) historyEntries += history.length;
      }
      if (tasks >= offloadTaskThreshold) return true;
      if (historyEntries >= offloadHistoryEntryThreshold) return true;
    }
    return false;
  }
}

/// Enkripsi/dekripsi yang tidak memblokir frame render untuk payload besar.
abstract final class BackgroundCrypto {
  static Future<String> encrypt(
    String content,
    String password, {
    int offloadThresholdChars = backgroundOffloadThresholdChars,
  }) {
    if (content.length < offloadThresholdChars) {
      return Future<String>.value(CryptoHelper.encrypt(content, password));
    }
    return compute(
      _encryptInBackground,
      _CryptoRequest(content: content, password: password),
    );
  }

  static Future<String> decrypt(
    String content,
    String password, {
    int offloadThresholdChars = backgroundOffloadThresholdChars,
  }) {
    if (content.length < offloadThresholdChars) {
      return Future<String>.value(CryptoHelper.decrypt(content, password));
    }
    return compute(
      _decryptInBackground,
      _CryptoRequest(content: content, password: password),
    );
  }
}

class _CryptoRequest {
  const _CryptoRequest({required this.content, required this.password});

  final String content;
  final String password;
}

Map<String, dynamic> _formattedMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('Akar JSON bukan objek.');
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

Map<String, dynamic> _decodeJsonInBackground(String content) {
  return _formattedMap(jsonDecode(content));
}

String _encodeJsonInBackground(Object? value) => jsonEncode(value);

String _prettyEncodeJsonInBackground(Object? value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}

String _encryptInBackground(_CryptoRequest request) {
  return CryptoHelper.encrypt(request.content, request.password);
}

String _decryptInBackground(_CryptoRequest request) {
  return CryptoHelper.decrypt(request.content, request.password);
}
