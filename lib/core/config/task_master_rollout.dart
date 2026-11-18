/// Saklar rollout Task Master.
///
/// Fase 5 memindahkan navigasi utama ke `task_master_new`. Modul lama tetap
/// tersedia sebagai fallback, tetapi tidak boleh menulis file selama saklar
/// baru aktif.
///
/// Rollback: ubah [taskMasterUseNewModule] menjadi `false`, lalu jalankan
/// ulang aplikasi. Prosedur lengkap ada di
/// `docs/tasks_master/ROLLBACK.md`.
const bool taskMasterUseNewModule = true;

/// Apakah modul Task Master lama masih boleh menulis file.
///
/// Nilainya diturunkan dari [taskMasterUseNewModule] agar tidak ada dua saklar
/// yang bisa saling bertentangan. Baca tetap diizinkan agar versi lama masih
/// bisa dipakai sebagai fallback darurat.
const bool taskMasterLegacyWritesEnabled = !taskMasterUseNewModule;
