# SPEC — Ad Banner Showcase

| Field | Value |
|---|---|
| Fitur | `ad_banner_showcase` |
| Sumber | `docs/ad_banner_showcase/PRD.md` |
| Status | Ready for Agent |
| Tanggal | 23 November 2026 |
| Platform Utama | Android |
| Platform Pendukung | Linux desktop (kompilasi lulus; banner mengembalikan SizedBox.shrink) |

---

## Problem Statement

Semua banner iklan yang tersebar di sembilan halaman aplikasi (Task Master, MyChecklist, MyChecklist Detail, MyNote, MyNote Detail, MyPrompt, MyPrompt Detail, My Documents, Data Center) tidak bisa dilihat sekaligus. Developer atau QA harus membuka setiap halaman satu per satu untuk memverifikasi placement, ukuran adaptif, dan status pemuatan iklan — proses yang lambat dan rentan terlewat.

Selain itu, tidak ada mekanisme untuk mensimulasikan refresh iklan tanpa harus menutup dan membuka kembali halaman secara manual. Hal ini menyulitkan pengujian skenario banner bergilir atau perilaku iklan pada jeda waktu tertentu.

---

## Solution

Tambahkan halaman `AdBannerShowcaseScreen` yang menampilkan semua slot banner secara vertikal (top-to-bottom) dalam satu tampilan bergulir. Halaman ini:

- Hanya dapat diakses melalui toggle eksperimental di Settings Dialog (key: `enable_ad_banner_showcase`).
- Menu di sidebar muncul/hilang secara dinamis mengikuti pola yang sama dengan Random Generator.
- Menyediakan kontrol refresh interval (30–300 detik, default 60 detik) yang tersimpan di SharedPreferences.
- Memanfaatkan `AdaptiveBannerAd` yang sudah ada — tidak ada widget iklan baru.
- Tidak membutuhkan dependensi baru.

---

## User Stories

### Aktivasi & Navigasi
1. Sebagai developer, saya ingin mengaktifkan toggle "Ad Banner Showcase" di Settings → Fitur Eksperimental, agar menu muncul di sidebar tanpa restart app.
2. Sebagai developer, saya ingin menonaktifkan toggle tersebut, agar menu hilang dari sidebar sehingga pengguna akhir tidak melihatnya.
3. Sebagai developer, saya ingin membuka halaman Ad Banner Showcase dari sidebar, agar saya bisa melihat semua slot iklan sekaligus.
4. Sebagai developer, saya ingin halaman ini memiliki tombol back/navigasi yang konsisten, agar navigasi terasa natural.

### Tampilan Banner
5. Sebagai developer, saya ingin melihat semua slot banner berjajar dari atas ke bawah dalam satu layar bergulir, agar saya bisa memvalidasi semua placement dalam satu sesi.
6. Sebagai developer, saya ingin setiap slot memiliki label nama (misalnya "Task Master", "MyChecklist Hub"), agar saya tahu slot iklan mana yang sedang saya lihat.
7. Sebagai developer, saya ingin banner yang gagal dimuat tidak menyebabkan crash atau ruang kosong besar, agar halaman tetap bisa digunakan.
8. Sebagai developer, saya ingin di platform non-Android halaman tetap terbuka tanpa error, agar build desktop tidak rusak.

### Refresh Interval
9. Sebagai developer, saya ingin mengatur interval refresh iklan (berapa detik), agar saya bisa mensimulasikan pergantian halaman dalam satu layar.
10. Sebagai developer, saya ingin nilai interval tersimpan saat saya keluar dan kembali ke halaman, agar saya tidak perlu mengatur ulang setiap kali.
11. Sebagai developer, saya ingin melihat countdown hingga refresh berikutnya, agar saya tahu kapan banner akan di-request ulang.
12. Sebagai developer, saya ingin interval minimum 30 detik, agar permintaan ke AdMob tidak terlalu agresif.
13. Sebagai developer, saya ingin me-trigger refresh manual tanpa menunggu timer, agar saya bisa menguji permintaan iklan kapan saja.

---

## Implementation Decisions

### ID.1 — Lokasi Fitur di Codebase

Fitur dibuat sebagai modul baru di:
```
lib/features/ad_banner_showcase/
  presentation/
    screens/
      ad_banner_showcase_screen.dart
    controllers/
      ad_showcase_controller.dart
```

Mengikuti struktur yang sama dengan modul `random` dan `documents`.

---

### ID.2 — Pola Eksperimental (SharedPreferences Flag)

Menggunakan pola yang identik dengan `enable_random_generator`:

**SharedPreferences key:** `enable_ad_banner_showcase`
**Default:** `false`

Di `SettingsDialog`:
- Tambah state `bool _enableAdBannerShowcase`
- Baca dari prefs di `_loadEncryptionSettings()`
- Tambah `ListTile` dengan `Switch` di bagian "Fitur Eksperimental"
- Toggle handler: simpan ke prefs via `prefs.setBool('enable_ad_banner_showcase', value)`

Di `DrawerMenu`:
- Tambah state `bool _showAdBannerShowcaseMenu = false`
- Tambah metode `_checkAdShowcaseMenuVisibility()` — dipanggil di `initState()` dan `_showSettingsDialog().then(...)`
- Tambah parameter `isAdShowcaseActive` ke konstruktor `DrawerMenu`
- Tambah `if (_showAdBannerShowcaseMenu)` block di `ListView` antara Random Generator dan Data Center
- Update `_reloadActiveScreen()` untuk menangani kasus `isAdShowcaseActive`

---

### ID.3 — Daftar Slot Iklan

Urutan dan key yang digunakan (dari `AdService._productionAdUnitsAndroid`):

```dart
static const List<({String label, String adKey})> adSlots = [
  (label: 'Task Master', adKey: 'task_master_banner'),
  (label: 'MyChecklist Hub', adKey: 'checklist_hub_banner'),
  (label: 'MyChecklist Detail', adKey: 'checklist_detail_banner'),
  (label: 'MyNote Hub', adKey: 'note_hub_banner'),
  (label: 'MyNote Detail', adKey: 'note_detail_banner'),
  (label: 'MyPrompt Hub', adKey: 'prompt_hub_banner'),
  (label: 'MyPrompt Detail', adKey: 'prompt_detail_banner'),
  (label: 'My Documents', adKey: 'document_hub_banner'),
  (label: 'Data Center', adKey: 'data_center'),
];
```

Ini prototype yang mengkodekan keputusan lebih tepat dari prosa: nama key harus **sama persis** dengan yang terdaftar di `AdService`, atau `getAdUnitId()` mengembalikan string kosong dan banner tidak tampil.

---

### ID.4 — Mekanisme Refresh Interval

**Controller** (`AdShowcaseController` — bisa `ChangeNotifier` atau plain class dengan callback):
- Menyimpan `int refreshIntervalSeconds` (default: 60, min: 30, max: 300).
- Membaca nilai dari SharedPreferences key `ad_showcase_refresh_interval_seconds` saat init.
- Menjalankan `Timer.periodic` dengan durasi `refreshIntervalSeconds`.
- Saat timer tiba: memperbarui `int _refreshKey` (integer yang diincrement), yang di-pass ke setiap slot sebagai `key: ValueKey(_refreshKey)`. Flutter akan dispose dan rebuild widget iklan secara otomatis.
- Menyediakan getter `int secondsUntilNextRefresh` yang dihitung dari waktu terakhir refresh.
- Metode `triggerManualRefresh()` untuk refresh segera.
- Dispose `Timer` di `dispose()`.

**Mengapa `ValueKey` bukan rebuild seluruh state:**
Hanya widget-widget dengan `key` yang berubah yang akan di-rebuild oleh Flutter. Ini lebih efisien dan selaras dengan cara `AdaptiveBannerAd` mengelola lifecycle-nya sendiri via `dispose()`.

---

### ID.5 — Layout Screen

```
AppBar("Ad Banner Showcase")
  └─ actions: [IconButton refresh manual]
Column (atas AppBar, bawah konten):
  └─ Row: [Label interval, Slider/DropDown 30-300s, Countdown Text]
ListView.builder (slot iklan):
  └─ Per item:
       Text(label, style: subtitle)
       AdaptiveBannerAd(key: ValueKey('${adKey}_$refreshKey'), adKey: adKey)
       Divider()
```

> Countdown timer menggunakan `Timer` terpisah yang tick setiap detik untuk update UI countdown — bukan untuk trigger refresh (agar tidak boros rebuild).

---

### ID.6 — Interval Setting Widget

Gunakan `DropdownButton<int>` dengan pilihan: 30, 60, 90, 120, 180, 300 (detik). Ini lebih aman dari slider karena nilai selalu valid dan tidak bisa diset di luar batas.

Saat nilai berubah:
1. Simpan ke SharedPreferences segera.
2. Reset timer (cancel lama, buat baru dengan durasi baru).
3. Reset countdown display.

---

### ID.7 — Platform Guard

`AdaptiveBannerAd` sudah memiliki guard di `AdService.getAdUnitId()`:
```dart
if (!Platform.isAndroid) return '';
```
Dan di `_AdaptiveBannerAdState._loadAdaptiveBanner()`:
```dart
final String adUnitId = AdService.getAdUnitId(widget.adKey);
if (adUnitId.isEmpty) return;
```

Tidak ada guard tambahan yang dibutuhkan di `AdBannerShowcaseScreen`. Layout akan render, banner tidak tampil (`SizedBox.shrink()`), tidak ada error.

---

### ID.8 — Tidak Ada Dependensi Baru

Semua komponen yang dibutuhkan sudah tersedia:
- `AdaptiveBannerAd` — `lib/core/presentation/widgets/adaptive_banner_ad.dart`
- `AdService` — `lib/core/services/ad_service.dart`
- `SharedPreferences` — sudah ada di `pubspec.yaml`
- `DrawerMenu`, `SettingsDialog` — dimodifikasi, tidak diganti

---

## Testing Decisions

### Apa yang membuat test baik untuk fitur ini

Test yang baik menguji **perilaku yang terlihat dari luar** (output/state), bukan implementasi internal (misalnya bukan "apakah Timer dibuat"). Hindari mock AdMob SDK — cukup guard dengan `kIsTest` atau mock `AdService.getAdUnitId`.

### Modul yang perlu diuji

| Modul | Jenis Test | Fokus |
|---|---|---|
| `AdShowcaseController` | Unit test | (a) Membaca interval dari SharedPreferences dengan benar; (b) `triggerManualRefresh()` mengincrement `refreshKey`; (c) `secondsUntilNextRefresh` berkurang setelah waktu berlalu; (d) Dispose tidak throw. |
| `DrawerMenu` | Widget test | Toggle `_showAdBannerShowcaseMenu` menyebabkan menu item muncul/hilang di tree. |
| `SettingsDialog` | Widget test | Switch "Ad Banner Showcase" menyimpan key `enable_ad_banner_showcase` ke SharedPreferences. |
| `AdBannerShowcaseScreen` | Widget test | Semua 9 label slot muncul di tree; DropdownButton interval render; tidak crash di platform non-Android (mock `Platform.isAndroid = false`). |

### Prior Art

- Test pola SharedPreferences flag: lihat cara `enable_random_generator` diuji jika sudah ada, atau buat dengan `shared_preferences` fake package (`SharedPreferences.setMockInitialValues`).
- Test widget `DrawerMenu` sudah ada polanya di file test yang ada di `/test/`.

---

## Out of Scope

- Halaman ini **tidak** mengimplementasikan tipe iklan baru (interstitial, native, rewarded).
- **Tidak** ada analytics atau logging khusus untuk showcase ini.
- **Tidak** ada mekanisme rolling refresh per-slot (semua slot refresh serentak).
- **Tidak** ada UI untuk menambah/hapus slot dari showcase — daftar slot bersifat statis sesuai `AdService`.
- Slot `jurnal_activity_banner` **tidak** disertakan dalam iterasi pertama (dapat ditambahkan sebagai enhancement).
- Halaman ini **tidak** tersedia di build production untuk end-user (terlindungi oleh flag eksperimental, bukan compile flag).

---

## Further Notes

- **Naming convention:** Ikuti pola `random_screen.dart` → `ad_banner_showcase_screen.dart`; pola key `enable_random_generator` → `enable_ad_banner_showcase`; pola method `_checkRandomMenuVisibility` → `_checkAdShowcaseMenuVisibility`.
- **Urutan menu di sidebar:** Letakkan setelah "Random Generator" dan sebelum "Data Center", agar semua menu eksperimental berkelompok.
- **Interval default 60 detik** dipilih karena AdMob merekomendasikan minimal 30 detik untuk refresh iklan banner. 60 detik memberikan ruang aman tanpa terlalu sering membuang impression.
- **ValueKey untuk rebuild:** Flutter menganggap widget dengan `key` berbeda sebagai widget baru — ini memicu `dispose()` dan `initState()` pada `AdaptiveBannerAd`, yang secara otomatis memuat iklan baru. Ini adalah cara yang idiomatik dan tidak memerlukan modifikasi pada `AdaptiveBannerAd`.
- **Tidak perlu menambah Ad Unit ID baru:** Semua key sudah terdaftar di `AdService._productionAdUnitsAndroid`. Jika di masa depan ada halaman baru dengan banner, cukup tambahkan entry baru ke map tersebut dan daftarkan di `adSlots`.
