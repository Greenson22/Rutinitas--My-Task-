import 'dart:io';
import 'package:flutter/foundation.dart';

class AdService {
  // ID Iklan Banner Test Resmi dari Google untuk Android
  static const String _testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  // 1. MAP UNTUK ID IKLAN ASLI (PRODUCTION ADS)
  static const Map<String, String> _productionAdUnitsAndroid = {
    'task_master_banner': 'ca-app-pub-5320800343545863/3489307539',
    'checklist_hub_banner': 'ca-app-pub-5320800343545863/2005101404',
    'checklist_detail_banner': 'ca-app-pub-5320800343545863/4439693059',
    'note_hub_banner': 'ca-app-pub-5320800343545863/7401887991',
    'note_detail_banner': 'ca-app-pub-5320800343545863/4775724658',
    'prompt_hub_banner': 'ca-app-pub-5320800343545863/7705140325',
    'prompt_detail_banner': 'ca-app-pub-5320800343545863/1957989622',
    'jurnal_activity_banner': 'ca-app-pub-5320800343545863/3079499608',
  };

  // 2. FUNGSI ADAPTIF UNTUK MENGAMBIL ID BERDASARKAN KUNCI (KEY)
  static String getAdUnitId(String adKey) {
    if (!Platform.isAndroid) return ''; // Khusus platform Android[cite: 5]

    if (kDebugMode) {
      // Jika mode debug/development, langsung gunakan ID Test tanpa Map duplikat[cite: 5]
      // Pengecekan `contains` memastikan kunci yang diminta memang valid terdaftar
      return _productionAdUnitsAndroid.containsKey(adKey)
          ? _testAndroidBannerId
          : '';
    } else {
      // Ambil dari Map Produksi jika aplikasi sudah rilis[cite: 5]
      return _productionAdUnitsAndroid[adKey] ?? '';
    }
  }
}
