import 'dart:io';
import 'package:flutter/foundation.dart';

class AdService {
  // 1. MAP UNTUK ID IKLAN PENGUJIAN (TEST ADS)
  static const Map<String, String> _testAdUnits = {
    'task_master_banner':
        'ca-app-pub-3940256099942544/6300978111', // ID Test Resmi Google
    'jurnal_interstitial': 'ca-app-pub-3940256099942544/1033173712',
    'checklist_rewarded': 'ca-app-pub-3940256099942544/5224354917',
  };

  // 2. MAP UNTUK ID IKLAN ASLI (PRODUCTION ADS)
  static const Map<String, String> _productionAdUnitsAndroid = {
    'task_master_banner':
        'ca-app-pub-5320800343545863/3489307539', // ID Asli Anda
    'jurnal_interstitial': 'ca-app-pub-xxxxxxxxxxxx/xxxxxxxxx',
    'checklist_rewarded': 'ca-app-pub-xxxxxxxxxxxx/xxxxxxxxx',
  };

  // 3. FUNGSI ADAPTIF UNTUK MENGAMBIL ID BERDASARKAN KUNCI (KEY)
  static String getAdUnitId(String adKey) {
    if (!Platform.isAndroid)
      return ''; // Sementara hanya untuk Android sesuai basis kode Anda

    if (kDebugMode) {
      // Ambil dari Map Testing jika dalam mode development
      return _testAdUnits[adKey] ?? '';
    } else {
      // Ambil dari Map Produksi jika sudah rilis
      return _productionAdUnitsAndroid[adKey] ?? '';
    }
  }
}
