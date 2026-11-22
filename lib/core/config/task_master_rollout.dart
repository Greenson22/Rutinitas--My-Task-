import 'package:shared_preferences/shared_preferences.dart';

/// Saklar rollout Task Master berbasis SharedPreferences (runtime preference).
///
/// Default adalah `false` (modul lama aktif). Saat saklar bernilai `true`,
/// modul baru `task_master_new` menjadi satu-satunya penulis dan tampilan utama.
/// Saat `false`, modul lama yang menulis dan modul baru tidak menulis.
const String taskMasterUseNewModulePrefKey = 'task_master_use_new_module';

/// Cache in-memory untuk status saklar Task Master New agar navigasi
/// berulang tidak perlu menunggu I/O SharedPreferences dan tidak berkedip.
bool? _cachedUseNewModule;

/// Mengambil nilai saklar runtime dari SharedPreferences (default: false).
/// Jika [useCache] bernilai true dan nilai sudah ter-cache di memori proses,
/// nilai cache akan langsung dikembalikan.
Future<bool> getTaskMasterUseNewModule({bool useCache = true}) async {
  if (useCache && _cachedUseNewModule != null) {
    return _cachedUseNewModule!;
  }
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getBool(taskMasterUseNewModulePrefKey) ?? false;
  _cachedUseNewModule = value;
  return value;
}

/// Menulis nilai saklar runtime ke SharedPreferences dan memperbarui cache.
Future<void> setTaskMasterUseNewModule(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(taskMasterUseNewModulePrefKey, value);
  _cachedUseNewModule = value;
}

/// Apakah modul Task Master lama diizinkan menulis.
///
/// Status ini diturunkan langsung dari saklar modul baru:
/// modul lama HANYA boleh menulis jika modul baru TIDAK aktif.
/// Guard ini membaca preferensi secara dinamis pada saat operasi dipanggil.
Future<bool> isTaskMasterLegacyWritesEnabled() async {
  final useNew = await getTaskMasterUseNewModule(useCache: false);
  return !useNew;
}

/// Helper untuk pengujian (test environment) untuk mengatur atau mereset cache.
void resetTaskMasterRolloutCacheForTesting([bool? cachedValue]) {
  _cachedUseNewModule = cachedValue;
}
