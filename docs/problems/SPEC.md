# SPEC — Rutinitasku: Paket Peningkatan UI/UX Q4 2026

**Referensi PRD:** [PRD.md](./PRD.md)
**Tanggal:** 2026-11-25
**Status:** Siap Implementasi

---

## Problem Statement

Pengguna menghadapi empat kelas masalah UX yang berbeda:

1. **Checklist Groups terlalu padat**: Ketika ada banyak grup checklist, layar penuh dengan card tanpa cara untuk merapikannya. Tidak ada cara untuk melipat (collapse) seksi atau menyembunyikannya sementara.

2. **Pindah Seksi di Checklist Detail terlalu panjang**: Daftar pilihan seksi tujuan selalu ditampilkan sekaligus, membuat panel aksi sangat panjang jika jumlah seksi banyak — sulit dipakai di perangkat kecil.

3. **Daftar "Hari Ini" tidak memberi umpan balik visual**: Semua tile tugas di daftar "Hari Ini" (Task Master New) tampak identik, tidak ada indikasi mana yang sudah selesai dan mana yang belum, sehingga pengguna harus membaca teks status secara cermat.

4. **Dashboard Task Master New kurang informatif**: Kartu "Target tercapai" hanya menampilkan angka tunggal tanpa konteks berapa total tugas yang ada hari ini, sehingga sulit menilai progres secara sekilas.

---

## Solution

1. **Checklist Groups**: Menambahkan fitur collapse per-seksi (ketuk header seksi → semua card tersembunyi) dan tombol sembunyi seksi di edit mode header. Default collapse dapat dikonfigurasi di halaman Pengaturan.

2. **Checklist Detail**: Daftar pilihan "Pindah Seksi" disembunyikan secara default dan baru muncul (lazy-expand dengan animasi) ketika tombol "Pindah Seksi" ditekan.

3. **Task Master New — Tile**: Tile tugas yang sudah mencapai target mendapat latar belakang hijau muda sebagai penanda visual instan.

4. **Task Master New — Dashboard**: Kartu "Target tercapai" diubah menjadi format "X / Y" di mana X = tugas tercapai dan Y = total tugas di daftar Hari Ini. Warna kartu ikut berubah (hijau jika semua selesai).

---

## User Stories

### Checklist Groups — Collapse

1. Sebagai pengguna, saya ingin mengetuk header seksi di Checklist Groups untuk menyembunyikan semua card di bawahnya, agar tampilan lebih ringkas saat ada banyak grup.
2. Sebagai pengguna, saya ingin ikon chevron di header seksi berubah arah (► tertutup, ▼ terbuka) agar saya bisa melihat status collapse dengan jelas.
3. Sebagai pengguna, saya ingin mengetuk header seksi yang sudah tertutup untuk membukanya kembali.
4. Sebagai pengguna, saya ingin seksi-seksi terbuka secara default ketika pertama kali membuka Checklist Groups, agar saya bisa melihat semua konten tanpa langkah ekstra.
5. Sebagai pengguna, saya ingin mengubah perilaku default (buka/tutup) di halaman Pengaturan, agar saya bisa menyesuaikan preferensi tampilan awal.
6. Sebagai pengguna, saya ingin state collapse reset setiap kali membuka ulang aplikasi (tidak persisten per seksi), agar tampilan selalu terprediksi.

### Checklist Groups — Sembunyi Seksi

7. Sebagai pengguna, saya ingin melihat tombol sembunyi (ikon mata) di edit mode header seksi pada Checklist Groups, agar saya bisa menyembunyikan seksi tertentu dari tampilan utama.
8. Sebagai pengguna, saya ingin seksi yang disembunyikan tetap menampilkan nama header dengan indikator "Tersembunyi", agar saya tahu ada data yang sedang disembunyikan.
9. Sebagai pengguna, saya ingin state sembunyi ini hanya berlaku di sesi aktif (tidak disimpan ke disk), agar restart aplikasi mengembalikan tampilan ke kondisi penuh.
10. Sebagai pengguna, saya ingin tombol sembunyi hanya muncul di edit mode (setelah long-press atau ketuk tombol edit pada header), agar tampilan normal tetap bersih.

### Checklist Detail — Pindah Seksi Lazy-Expand

11. Sebagai pengguna, saya ingin menekan tombol atau opsi "Pindah Seksi" di panel aksi checklist detail untuk memunculkan daftar seksi sebagai pilihan, bukan melihatnya selalu terbuka.
12. Sebagai pengguna, saya ingin daftar seksi muncul dengan animasi expand halus ketika saya menekan "Pindah Seksi".
13. Sebagai pengguna, saya ingin menekan nama seksi tujuan dari daftar yang muncul, dan kartu langsung berpindah ke seksi tersebut.
14. Sebagai pengguna, saya ingin dialog tidak otomatis tertutup setelah saya memilih seksi, agar saya bisa melanjutkan aksi lain di dalam dialog yang sama.
15. Sebagai pengguna, saya ingin menekan "Pindah Seksi" sekali lagi untuk menutup daftar jika saya berubah pikiran.
16. Sebagai pengguna, saya ingin seksi saat ini tidak muncul di daftar pilihan, agar saya tidak memilih tujuan yang sama.

### Task Master New — Pewarnaan Tile Selesai

17. Sebagai pengguna, saya ingin melihat latar belakang hijau muda pada tile tugas yang sudah mencapai target hariannya di daftar Hari Ini, agar saya bisa sekilas tahu progres harian tanpa membaca teks.
18. Sebagai pengguna, saya ingin tile tugas yang belum mencapai target tetap berwarna normal (putih/transparan), agar kontras visual antara selesai dan belum selesai jelas.
19. Sebagai pengguna, saya ingin tile tugas tanpa target (counter tanpa target) tidak mendapat pewarnaan khusus, agar tidak membingungkan.
20. Sebagai pengguna, saya ingin teks dan ikon di dalam tile tetap sama meskipun ada pewarnaan latar, agar keterbacaan tidak terganggu.

### Task Master New — Dashboard Kartu "X/Y"

21. Sebagai pengguna, saya ingin melihat kartu statistik dengan nilai "X / Y" (misalnya "2 / 5") di dashboard, yang menunjukkan berapa tugas sudah mencapai target dari total yang ada di daftar Hari Ini.
22. Sebagai pengguna, saya ingin angka Y pada kartu merepresentasikan hanya tugas yang muncul di daftar Hari Ini (bukan semua tugas aktif), agar angka relevan dengan yang saya lihat.
23. Sebagai pengguna, saya ingin warna kartu berubah menjadi hijau ketika semua tugas di daftar Hari Ini sudah tercapai, sebagai sinyal positif motivasi.
24. Sebagai pengguna, saya ingin warna kartu tetap oranye selama masih ada tugas yang belum tercapai, sebagai pengingat untuk terus bekerja.
25. Sebagai pengguna, saya ingin kartu ini tetap menampilkan "0 / 0" (atau format yang masuk akal) ketika tidak ada tugas di daftar Hari Ini, tanpa crash.

---

## Implementation Decisions

### Bagian 1 — Checklist Groups: Collapse

**1.1 State collapse di DailyController**

State collapse disimpan sebagai `Map<String, bool>` di `DailyController`. Key adalah nama seksi (`sectionCategory`). State ini bersifat ephemeral (memori sesi) — tidak ditulis ke disk. Hanya nilai default globalnya yang persisten via `SharedPreferences`.

Kunci SharedPreferences yang digunakan:
- `'checklist_groups_default_collapsed'` → `bool`, default `false`

Method yang ditambahkan ke `DailyController`:
- `bool isSectionCollapsed(String sectionKey)` → membaca dari map, fallback ke default
- `void toggleSectionCollapsed(String sectionKey)` → flip nilai di map, panggil `notifyListeners()`
- State default dimuat saat `loadGroupsData()` pertama kali dipanggil

**1.2 Sambungan ke GroupedSectionLayout**

`DailyScreen` menyambungkan `isSectionCollapsed` callback ke parameter `GroupedSectionLayout.isSectionCollapsed` yang sudah ada. `GroupedSectionLayout` sudah menangani `AnimatedCrossFade` untuk show/hide konten — tidak perlu modifikasi di widget ini.

**1.3 Header seksi menggunakan InteractiveSectionHeader**

`DailyScreen` akan menggunakan `InteractiveSectionHeader` (dari `core/presentation/widgets/`) sebagai builder header seksi, menggantikan header inline yang ada. Parameter warna tema: `Colors.indigo` (konsisten dengan tema Checklist Groups saat ini).

Prop yang perlu disambungkan:
- `isCollapsed: _controller.isSectionCollapsed(sectionKey)`
- `onToggleCollapse: () => _controller.toggleSectionCollapsed(sectionKey)`

**1.4 Pengaturan default di SettingsDialog**

`SettingsDialog` mendapat satu `SwitchListTile` baru di bawah bagian tampilan:
- Label: `'Checklist Groups: Tutup seksi secara default'`
- Membaca/menulis kunci `'checklist_groups_default_collapsed'` di `SharedPreferences`

---

### Bagian 2 — Checklist Groups: Sembunyi Seksi

**2.1 State hidden di DailyController**

State hidden seksi disimpan sebagai `Map<String, bool>` terpisah di `DailyController` (berbeda dari `_collapsedSections`). Juga ephemeral. Dibedakan karena semantiknya berbeda: collapse = ketuk header, hidden = aksi eksplisit di edit mode.

Method baru:
- `bool isSectionHidden(String sectionKey)`
- `void toggleSectionHidden(String sectionKey)`

**2.2 Rendering**

Header seksi yang hidden tetap dirender (agar pengguna bisa unhide), tapi `isSectionHidden == true` sama efeknya dengan `isSectionCollapsed == true` di `GroupedSectionLayout.isSectionCollapsed`. Implementasi: callback `isSectionCollapsed` di `DailyScreen` menggabungkan keduanya:

```
(key) => _controller.isSectionCollapsed(key) || _controller.isSectionHidden(key)
```

`InteractiveSectionHeader` sudah punya `isHidden` dan `onToggleVisibility` props — disambungkan ke controller.

---

### Bagian 3 — Checklist Detail: Pindah Seksi Lazy-Expand

**3.1 Lokasi modifikasi**

Modifikasi dilakukan di `ChecklistControlPanel` — panel bawah di dalam `DailyChecklistDialog`. Pengguna mengkonfirmasi tombol "Pindah Seksi" ada di sini.

**3.2 State expand**

`ChecklistControlPanel` menjadi `StatefulWidget` (jika belum), dengan field lokal:
- `bool _isSectionPickerExpanded = false`

**3.3 Interaksi**

Ketuk "Pindah Seksi" → toggle `_isSectionPickerExpanded`. Daftar seksi dibungkus dengan `AnimatedSize` (durasi 200 ms, curve `Curves.easeInOut`), identik dengan pola yang dipakai `MoveSelectedItemsDialog._isInternalMenuExpanded`.

Setelah pengguna memilih seksi tujuan:
- Panggil callback pemindahan di controller
- Set `_isSectionPickerExpanded = false` (tutup picker)
- Dialog tidak di-pop otomatis

Seksi saat ini difilter dari daftar pilihan:
```
currentGroup.allList.where((s) => s.sectionName != subject.section)
```

**3.4 Parameter yang dibutuhkan ChecklistControlPanel**

`ChecklistControlPanel` perlu menerima:
- Daftar `ChecklistSection` dari grup saat ini
- Nama seksi aktif subjek yang sedang dibuka
- Callback untuk memindahkan subjek ke seksi tujuan

---

### Bagian 4 — Task Master New: Dashboard

**4A — Pewarnaan TodayTaskTile**

Widget `TodayTaskTile` dimodifikasi: container terluar (`Padding`) diganti dengan `Container` yang memiliki `BoxDecoration` kondisional.

Warna: `const Color(0xFFE8F5E9)` (Material Green 50) ketika `targetMet == true`, transparan saat lainnya. Menggunakan konstanta warna statis (bukan `withOpacity`) agar tidak dipengaruhi warna latar Card.

`targetMet` sudah tersedia sebagai variabel lokal di `build()` via `isTaskTargetMetToday(task, todayKey)` — tidak perlu mengubah interface widget.

**4B — Kartu Dashboard "X/Y"**

`DashboardSummaryCards` mendapat satu parameter baru: `int todayTasksTotalCount`.

Kartu ketiga (`summaryCompletedTargets`) berubah:
- `value`: dari `'$completedTargetsToday'` menjadi `'$completedTargetsToday / $todayTasksTotalCount'`
- `color`: dari statis `Colors.orange[800]!` menjadi ekspresi kondisional:
  - `Colors.green[700]!` jika `completedTargetsToday == todayTasksTotalCount && todayTasksTotalCount > 0`
  - `Colors.orange[800]!` selain itu (termasuk `todayTasksTotalCount == 0`)

`todayTasksTotalCount` dihitung di `TaskMasterNewScreen` dari `todayTasks.length` dan diteruskan ke `DashboardSummaryCards`. Ini berlaku di dua tempat: `_buildSinglePaneReady` dan `_buildDesktopDashboard`.

---

## Testing Decisions

### Kriteria Test yang Baik

- Uji **perilaku yang dapat diamati pengguna** — apa yang muncul di widget tree dan bagaimana interaksi mengubahnya. Jangan uji detail implementasi (nama variabel internal, jumlah `notifyListeners()`, dll.).
- Gunakan **fake repository/gateway** yang sudah ada (pola di `test/features/task_master_new/support/`) untuk isolasi dari I/O.
- Gunakan **widget test dengan `ChecklistDetailScreen` atau `TaskMasterNewScreen`** langsung — bukan unit test state terisolasi — agar coverage mencakup integrasi controller ↔ widget.
- Semua test widget checklist mengatur `tester.view.physicalSize = const Size(1080, 1920)` untuk mencegah overflow (pola baku yang sudah ada).
- Test SharedPreferences menggunakan `SharedPreferences.setMockInitialValues({...})` (pola dari `checklist_section_collapse_ticket_05_test.dart`).

### Modul yang Diuji

**Bagian 1 & 2 — Checklist Groups Collapse & Hidden**

File baru: `test/features/checklist/presentation/checklist_groups_collapse_hidden_test.dart`

Seam: `DailyScreen` (widget test penuh). Saat ini `DailyScreen` membaca dari file disk melalui `DailyController`, tapi test bisa menyuntikkan `ChecklistGroup` via konstruktor `GroupedSectionLayout` jika tersedia, atau menggunakan temp directory seperti pola di `checklist_section_hide_ticket_03_test.dart`.

Skenario yang dicakup:
- Ketuk header seksi → konten hilang dari widget tree, chevron berubah ke `►`
- Ketuk header seksi lagi → konten muncul kembali, chevron berubah ke `▼`
- Dengan `'checklist_groups_default_collapsed': true` → seksi dimulai tertutup
- Dengan `'checklist_groups_default_collapsed': false` → seksi dimulai terbuka (default)
- Long-press header → edit mode → tombol sembunyi muncul → ketuk → header menampilkan badge "Tersembunyi", konten hilang
- State collapse & hidden reset antar sesi (tidak persisten per-seksi)

**SettingsDialog** (tambahkan ke test yang sudah ada atau buat sub-group baru):
- Switch "Tutup seksi secara default" tersedia dan menulis ke `'checklist_groups_default_collapsed'`

Preseden: `checklist_section_collapse_ticket_05_test.dart` dan `checklist_section_hide_ticket_03_test.dart`

---

**Bagian 3 — Pindah Seksi Lazy-Expand**

File baru: `test/features/checklist/presentation/checklist_control_panel_section_picker_test.dart`

Seam: `DailyChecklistDialog` atau `ChecklistControlPanel` langsung (widget test). Suntikkan `ChecklistGroup` yang sudah memiliki beberapa `ChecklistSection` tanpa I/O nyata.

Skenario yang dicakup:
- Daftar seksi tidak terlihat secara default (widget tidak ada di tree)
- Ketuk "Pindah Seksi" → daftar seksi muncul (semua seksi kecuali seksi saat ini)
- Ketuk seksi tujuan → item berpindah, picker tertutup, dialog tetap terbuka
- Ketuk "Pindah Seksi" lagi saat terbuka → picker tertutup
- Seksi aktif tidak muncul di daftar pilihan

Preseden: `checklist_detail_controller_ticket_02_test.dart`

---

**Bagian 4A — TodayTaskTile Pewarnaan**

Tambahkan test ke: `test/features/task_master_new/presentation/dashboard_test.dart`

Skenario yang dicakup:
- Tile tugas yang `isTaskTargetMetToday == true` memiliki `Container` dengan warna `Color(0xFFE8F5E9)`
- Tile tugas yang belum tercapai tidak memiliki warna hijau
- Tile tugas tanpa target tidak memiliki warna hijau

Cara verifikasi: cari `Container` ancestor dari key `'todayTask_<id>'` dan periksa `decoration.color`.

Preseden: test `summaryValue` di `dashboard_test.dart` dan penggunaan `Key` di `TodayTaskTile`

---

**Bagian 4B — DashboardSummaryCards "X/Y"**

Tambahkan test ke: `test/features/task_master_new/presentation/dashboard_test.dart`

Skenario yang dicakup:
- Nilai kartu `summaryCompletedTargets` menampilkan format `"X / Y"` bukan hanya `"X"`
- Y = jumlah tugas yang muncul di daftar Hari Ini (bukan `activeTaskCount`)
- Kartu berwarna hijau ketika X == Y && Y > 0
- Kartu berwarna oranye ketika X < Y atau Y == 0
- Tidak crash ketika tidak ada tugas di daftar Hari Ini (`todayTasksTotalCount == 0` → "0 / 0")

Preseden: `summaryValue(tester, 'summaryCompletedTargets')` sudah ada di test suite

---

## Out of Scope

- **Persist state collapse/hidden per-seksi ke disk** — keputusan ADR-001: state per-seksi ephemeral, hanya default global yang persisten.
- **Collapse individual per-card ChecklistGroup** — hanya collapse per-seksi yang diimplementasikan.
- **Animasi/transisi collapse di Checklist Groups yang berbeda** dari `AnimatedCrossFade` yang sudah ada di `GroupedSectionLayout`.
- **Kartu dashboard kelima** — diputuskan untuk memodifikasi kartu ketiga yang sudah ada, bukan menambah kartu baru.
- **Strikethrough atau ikon centang pada tile selesai** — hanya pewarnaan background.
- **Pindah Seksi di Checklist Groups** (layar utama grup) — ini sudah ada dan tidak diubah.
- **Perubahan model data `ChecklistGroup` atau `DailySubject`** — semua state baru adalah ephemeral di controller atau UI state lokal.

---

## Further Notes

- **Breaking change di `DashboardSummaryCards`**: Menambah parameter `todayTasksTotalCount` sebagai required akan membutuhkan update semua pemanggil. Periksa apakah ada pemanggil di test file yang perlu diperbarui (`dashboard_test.dart` memanggil `DashboardSummaryCards` via `TaskMasterNewScreen` — tidak langsung, jadi tidak ada update test diperlukan untuk signature).
- **`ChecklistControlPanel` mungkin perlu refactor ke `StatefulWidget`**: Jika saat ini masih `StatelessWidget`, perlu diubah untuk menyimpan `_isSectionPickerExpanded`. Periksa implementasi saat ini sebelum modifikasi.
- **Pola kunci SharedPreferences**: Kunci baru `'checklist_groups_default_collapsed'` perlu didokumentasikan bersama kunci yang sudah ada (`'section_default_collapsed'` untuk checklist detail) agar tidak terjadi konflik atau kebingungan naming.
- **Konsistensi warna**: Pastikan `Color(0xFFE8F5E9)` untuk tile selesai tidak bentrok dengan warna custom yang bisa diset pengguna pada `DailySubject.backgroundColor`. Tile di Task Master New tidak memiliki warna kustom, jadi ini aman.
