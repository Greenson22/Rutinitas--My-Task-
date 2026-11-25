# PRD — Rutinitasku: Paket Peningkatan UI/UX Q4 2026

**Tanggal:** 2026-11-25
**Status:** ✅ Final — Siap Implementasi
**Ditulis oleh:** Antigravity (sesi /grill-with-docs, keputusan dikonfirmasi pengguna)

---

## Ringkasan Eksekutif

Dokumen ini mencakup empat kelompok peningkatan fungsional pada aplikasi **Rutinitasku** (Flutter). Semua keputusan desain telah dikonfirmasi pengguna melalui sesi grilling. Peningkatan mencakup:

1. **Checklist Groups** — fitur collapse per-seksi
2. **Checklist Groups** — tombol sembunyi seksi (visual) di edit mode
3. **Checklist Detail** — daftar pilihan pindah seksi yang lazy-expand
4. **Task Master New** — pewarnaan tile selesai + kartu statistik "X/Y hari ini"

---

## Bagian 1 — Checklist Groups: Fitur Collapse per Seksi

### Problem Statement

Layar `DailyScreen` menggunakan `GroupedSectionLayout` yang sudah mendukung parameter `isSectionCollapsed`, tapi fitur ini **belum diaktifkan** di Checklist Groups. Pengguna tidak bisa merapikan tampilan ketika banyak grup.

### Keputusan

- **Collapse berlaku per-seksi**: satu ketukan pada header seksi menyembunyikan semua card di bawahnya.
- **State disimpan di memori** (`Map<String, bool>` di `DailyController`), reset saat restart app.
- **Default: terbuka** (`isCollapsed = false`), tapi bisa diubah via pengaturan global.
- **Pengaturan default global** disimpan di `SharedPreferences` via `StorageService` yang sudah ada.
- Animasi menggunakan `AnimatedCrossFade` yang sudah ada di `GroupedSectionLayout`.

### User Stories

1. Sebagai pengguna, saya ingin mengetuk header seksi di Checklist Groups untuk menyembunyikan semua card di bawahnya, agar tampilan lebih ringkas.
2. Sebagai pengguna, saya ingin ikon chevron di header seksi berubah arah (▶ tertutup, ▼ terbuka) agar state collapse jelas terlihat.
3. Sebagai pengguna, saya ingin mengatur agar semua seksi defaultnya tertutup saat membuka Checklist Groups, via halaman Pengaturan.

### Spesifikasi Teknis

**`DailyController` (tambah):**
```dart
Map<String, bool> _collapsedSections = {};
bool defaultCollapseState = false; // dibaca dari SharedPreferences key: 'checklist_groups_default_collapsed'

bool isSectionCollapsed(String sectionKey) =>
    _collapsedSections[sectionKey] ?? defaultCollapseState;

void toggleSectionCollapsed(String sectionKey) {
  _collapsedSections[sectionKey] = !isSectionCollapsed(sectionKey);
  notifyListeners();
}

Future<void> loadCollapsePreference() async {
  // baca SharedPreferences 'checklist_groups_default_collapsed'
  defaultCollapseState = prefs.getBool('checklist_groups_default_collapsed') ?? false;
}
```

**`DailyScreen.build()` (ubah):**
```dart
GroupedSectionLayout(
  isSectionCollapsed: (key) => _controller.isSectionCollapsed(key),
  sectionHeaderBuilder: (ctx, index, sectionKey, isEditMode) {
    // ... render header dengan onToggleCollapse
    return InteractiveSectionHeader(
      sectionName: sectionKey,
      isCollapsed: _controller.isSectionCollapsed(sectionKey),
      onToggleCollapse: () => _controller.toggleSectionCollapsed(sectionKey),
      // ... parameter lain
    );
  },
)
```

**`SettingsDialog` (tambah):**
```dart
SwitchListTile(
  title: const Text('Checklist Groups: Default Tertutup'),
  subtitle: const Text('Semua seksi akan tertutup saat membuka Checklist Groups'),
  value: /* baca dari prefs */,
  onChanged: (val) { /* simpan ke prefs */ },
)
```

> [!NOTE]
> `InteractiveSectionHeader` sudah mendukung `onToggleCollapse` dan `isCollapsed`. DailyScreen perlu menyambungkan prop ini yang sebelumnya tidak diisi.

---

## Bagian 2 — Checklist Groups: Tombol "Sembunyi Seksi" di Edit Mode

### Problem Statement

Header seksi di `DailyScreen` tidak memiliki tombol untuk menyembunyikan isi seksi secara visual. Pengguna tidak bisa merapikan tampilan tanpa menghapus data.

### Keputusan

- **Sembunyi = collapse visual saja**: state hanya di memori, tidak ada perubahan data ke disk.
- Tombol muncul **hanya saat edit mode aktif** (setelah long-press pada header seksi), konsisten dengan pola `InteractiveSectionHeader`.
- Ini **berbeda** dari fitur collapse di Bagian 1: collapse (Bagian 1) di-trigger ketuk header, sembunyi (Bagian 2) adalah aksi eksplisit di edit mode.
- Karena ini visual-only di memori, implementasinya identik dengan collapse — cukup reuse state yang sama.

### User Stories

4. Sebagai pengguna, saya ingin menekan tombol mata (`visibility_off`) di edit mode header seksi untuk menyembunyikan seluruh isi seksi dari tampilan.
5. Sebagai pengguna, saya ingin header seksi yang tersembunyi tetap menampilkan nama seksi dengan indikator "Tersembunyi" agar saya tahu ada data di sana.

### Spesifikasi Teknis

**`InteractiveSectionHeader`** sudah punya `onToggleVisibility` dan `isHidden`. Di `DailyScreen`, sambungkan:

```dart
InteractiveSectionHeader(
  isHidden: _controller.isSectionHidden(sectionKey), // state visual baru
  onToggleVisibility: () => _controller.toggleSectionHidden(sectionKey),
  // ...
)
```

**`DailyController` (tambah):**
```dart
// State visual-only, terpisah dari isCollapsed
Map<String, bool> _hiddenSections = {};

bool isSectionHidden(String sectionKey) => _hiddenSections[sectionKey] ?? false;
void toggleSectionHidden(String sectionKey) {
  _hiddenSections[sectionKey] = !isSectionHidden(sectionKey);
  notifyListeners();
}
```

**`DailyScreen.build()` (ubah logic rendering):**
```dart
// Filter sectionKeys untuk menyembunyikan seksi yang di-hidden
final List<String> visibleKeys = allKeys
    .where((k) => !_controller.isSectionHidden(k))
    .toList();
// Tapi tetap render header untuk seksi tersembunyi dengan style redup
```

> [!TIP]
> Karena collapsed (Bagian 1) dan hidden (Bagian 2) sama-sama "sembunyikan konten secara visual", keduanya bisa digabung menjadi satu kondisi `isSectionHidden || isSectionCollapsed` untuk mempersingkat logika rendering. Bedanya: collapsed di-trigger ketuk header, hidden di-trigger tombol di edit mode.

---

## Bagian 3 — Checklist Detail: Pindah Seksi Lazy-Expand

### Problem Statement

Di dalam `ChecklistControlPanel` (panel aksi bawah `DailyChecklistDialog`), daftar pilihan "Pindah Seksi" ditampilkan langsung semuanya, membuat dialog sangat panjang jika seksi banyak.

### Keputusan

- Daftar seksi **tersembunyi secara default**, muncul hanya ketika tombol "Pindah Seksi" ditekan.
- Gunakan pola `AnimatedSize` + toggle bool, identik dengan `MoveSelectedItemsDialog._isInternalMenuExpanded`.
- Setelah pengguna memilih seksi tujuan → pindahkan item → dialog tetap terbuka (tidak auto-close).

### User Stories

6. Sebagai pengguna, saya ingin menekan tombol "Pindah Seksi" di panel aksi checklist detail untuk memunculkan daftar seksi sebagai pilihan, bukan melihatnya langsung.
7. Sebagai pengguna, saya ingin menekan seksi tujuan dari daftar yang muncul, dan item langsung berpindah tanpa menutup dialog.

### Spesifikasi Teknis

**`ChecklistControlPanel` atau bagian relevan di `DailyChecklistDialog`:**

```dart
// Tambah state
bool _isSectionPickerExpanded = false;

// Widget pindah seksi
InkWell(
  onTap: () => setState(() => _isSectionPickerExpanded = !_isSectionPickerExpanded),
  child: Row(
    children: [
      const Icon(Icons.drive_file_move_outlined, size: 18),
      const SizedBox(width: 6),
      const Text('Pindah Seksi'),
      Icon(_isSectionPickerExpanded
        ? Icons.keyboard_arrow_down_rounded
        : Icons.keyboard_arrow_right_rounded),
    ],
  ),
),
AnimatedSize(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  child: _isSectionPickerExpanded
    ? Column(
        children: currentGroup.allList
            .where((s) => s.sectionName != subject.section)
            .map((section) => ListTile(
              title: Text(section.sectionName),
              onTap: () {
                _isSectionPickerExpanded = false;
                // panggil moveSectionItem(...)
              },
            ))
            .toList(),
      )
    : const SizedBox(width: double.infinity, height: 0),
),
```

> [!NOTE]
> Pastikan `ChecklistControlPanel` menerima parameter `currentGroup` atau daftar seksi (`List<ChecklistSection>`) agar widget ini tidak perlu mengakses data secara langsung.

---

## Bagian 4A — Task Master New: Pewarnaan Tile Selesai

### Problem Statement

Daftar "Hari Ini" di `TaskMasterNewScreen` tidak memberikan indikasi visual mana tugas yang sudah selesai (target tercapai) versus yang belum.

### Keputusan

- **Background tile hijau muda subtle** (`Colors.green.withOpacity(0.07)` atau `Color(0xFFE8F5E9)`) ketika `isTaskTargetMetToday == true`.
- Teks dan ikon tetap normal (tidak dicoret, tidak berubah warna).
- Tugas tanpa target (`Tanpa target`) tidak mendapat pewarnaan khusus.

### User Stories

8. Sebagai pengguna, saya ingin melihat latar belakang hijau muda pada tile tugas yang sudah mencapai targetnya di daftar Hari Ini, agar saya bisa sekilas tahu progres harian.
9. Sebagai pengguna, saya ingin tile tugas yang belum selesai tetap tampil normal tanpa warna, agar kontras dengan yang sudah selesai jelas terlihat.

### Spesifikasi Teknis

**`TodayTaskTile.build()` (ubah Padding terluar):**

```dart
// Ganti Padding dengan Container
Container(
  key: Key('todayTask_${task.id}'),
  decoration: BoxDecoration(
    color: targetMet
        ? Colors.green.withOpacity(0.07) // ✅ Selesai
        : Colors.transparent,            // ⬜ Belum / Tanpa target
    borderRadius: BorderRadius.circular(8),
  ),
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Row(/* ... isi yang sama ... */),
)
```

> [!TIP]
> Gunakan warna `const Color(0xFFE8F5E9)` (Material Green 50) alih-alih `withOpacity` agar tidak terpengaruh warna latar Card.

---

## Bagian 4B — Task Master New: Kartu "X/Y Tugas Hari Ini"

### Problem Statement

Kartu "Target tercapai" di `DashboardSummaryCards` hanya menampilkan angka tunggal (jumlah target tercapai) tanpa konteks berapa total tugas di daftar Hari Ini.

### Keputusan

- **Ubah kartu "Target tercapai"** menjadi kartu dengan nilai `"X / Y"` di mana:
  - **X** = jumlah tugas dengan `isTaskTargetMetToday == true` di daftar Hari Ini
  - **Y** = `todayTasks.length` (total tugas yang muncul di daftar Hari Ini)
- Label kartu tetap dapat dikustomisasi (mis: "Tercapai hari ini" atau "Progress hari ini").
- Menggunakan data yang sudah ada: `completedTargets` (dari `completedTargetCount(...)`) dan `todayTasks.length`.

### User Stories

10. Sebagai pengguna, saya ingin melihat kartu "X / Y" di dashboard yang menunjukkan berapa tugas sudah selesai dari total tugas hari ini, agar saya bisa memotivasi diri.
11. Sebagai pengguna, saya ingin angka Y pada kartu merepresentasikan hanya tugas yang muncul di daftar Hari Ini (bukan semua tugas aktif), agar angka relevan dengan konteks.

### Spesifikasi Teknis

**`TaskMasterNewScreen` — ubah pemanggilan `DashboardSummaryCards`:**

```dart
// Hitung total tugas di daftar Hari Ini
final todayTasksTotalCount = todayTasks.length;

DashboardSummaryCards(
  activeCategoryCount: data.activeCategoryCount,
  activeTaskCount: data.activeTaskCount,
  completedTargetsToday: completedTargets,
  todayTasksTotalCount: todayTasksTotalCount, // BARU
  journalMinutesToday: _controller.journalTodayMinutes,
),
```

**`DashboardSummaryCards` (ubah parameter + widget):**

```dart
// Tambah parameter
final int todayTasksTotalCount;

// Ubah kartu "Target tercapai"
_SummaryStatCard(
  cardKey: const Key('summaryCompletedTargets'),
  icon: Icons.flag_rounded,
  label: 'Tercapai hari ini',
  value: '$completedTargetsToday / $todayTasksTotalCount', // X / Y
  color: completedTargetsToday == todayTasksTotalCount && todayTasksTotalCount > 0
      ? Colors.green[700]!   // ✅ Semua selesai
      : Colors.orange[800]!, // ⏳ Sebagian / belum
),
```

> [!NOTE]
> Warna kartu berubah dinamis: oranye jika belum semua selesai, hijau tua jika semua Y tugas sudah X (semua tercapai). Ini memberi umpan balik visual positif.

---

## Glossary Domain

| Istilah | Definisi | Lokasi Kode |
|---|---|---|
| **ChecklistGroup** | Satu berkas JSON grup checklist (mis: "Pekerjaan"). Punya `sectionCategory` untuk pengelompokan visual. | `daily_model.dart` |
| **ChecklistSection** | Seksi internal dalam satu ChecklistGroup (mis: "PRIORITAS"). Berisi `DailySubject` items. | `daily_model.dart` |
| **DailySubject** | Satu kartu materi/tugas dalam ChecklistGroup. Punya sub-materi bersarang dan properti `section`. | `daily_model.dart` |
| **TodayTaskEntry** | Wrapper `{ Category + Task }` untuk daftar "Hari Ini" di Task Master New. | `dashboard_summary.dart` |
| **sectionCategory** | String pada `ChecklistGroup` yang menentukan pengelompokan visual di `DailyScreen`. | `daily_model.dart` |
| **isSectionCollapsed** | Fungsi callback di `GroupedSectionLayout` yang menentukan apakah konten seksi disembunyikan secara visual (animasi `AnimatedCrossFade`). | `grouped_section_layout.dart` |
| **todayKey** | String `"yyyy-MM-dd"` yang merepresentasikan hari ini, digunakan sebagai kunci hitungan harian. | `task_master_controller.dart` |
| **targetDaily** | Jumlah minimum pengerjaan per hari agar `isTaskTargetMetToday == true`. | `task.dart`, `dashboard_summary.dart` |
| **isTaskTargetMetToday** | Fungsi yang menghitung apakah satu task sudah mencapai targetnya hari ini. | `dashboard_summary.dart:40` |
| **completedTargetCount** | Fungsi agregat yang menghitung jumlah `TodayTaskEntry` yang sudah `isTaskTargetMetToday`. | `dashboard_summary.dart:83` |

---

## ADR (Architecture Decision Records)

### ADR-001: Collapse & Hidden State — Memory Only (✅ Diputuskan)

State collapse dan hidden di Checklist Groups disimpan di **memori saja** (`Map<String, bool>` di `DailyController`). Reset tiap app restart.

**Alasan:** Pengguna mengkonfirmasi ini cukup. Menyederhanakan implementasi dan menghindari disk I/O tambahan.

**Pengecualian:** Hanya **default global** (buka/tutup) yang dipersist ke `SharedPreferences` via kunci `'checklist_groups_default_collapsed'`.

### ADR-002: Reuse `InteractiveSectionHeader` di DailyScreen (✅ Direkomendasikan)

`DailyScreen` akan menggunakan `InteractiveSectionHeader` dari `core/presentation/widgets/` alih-alih header inline kustom.

**Manfaat:**
- Mendapatkan fitur collapse + visibility secara gratis
- Mengurangi duplikasi kode ~50 baris
- Konsistensi UI antar layar

**Penyesuaian yang diperlukan:**
- Ganti `themeColor` menjadi `Colors.indigo` (DailyScreen) vs `Colors.teal[800]` (Checklist Detail)
- Pastikan callback `onToggleCollapse` dan `onToggleVisibility` terhubung ke `DailyController`

### ADR-003: Kartu Dashboard "X/Y" — Modifikasi In-Place (✅ Diputuskan)

Kartu "Target tercapai" dimodifikasi in-place menjadi format `"X / Y"`. Tidak ada kartu baru ditambahkan.

**Alasan:** Menjaga layout 2×2 yang sudah ada. Menambah parameter `todayTasksTotalCount` ke `DashboardSummaryCards` adalah perubahan backward-compatible (tambah parameter required baru → perlu update semua pemanggil).

---

## Checklist Implementasi

### Sprint: Checklist Groups (Bagian 1 & 2)

- [ ] `DailyController`: Tambah `Map<String, bool> _collapsedSections` dan `_hiddenSections`
- [ ] `DailyController`: Tambah method `isSectionCollapsed`, `toggleSectionCollapsed`, `isSectionHidden`, `toggleSectionHidden`
- [ ] `DailyController`: Load `defaultCollapseState` dari `SharedPreferences` di `loadGroupsData()`
- [ ] `DailyScreen`: Hubungkan `isSectionCollapsed` ke `GroupedSectionLayout`
- [ ] `DailyScreen`: Gunakan `InteractiveSectionHeader` di `sectionHeaderBuilder` dengan collapse & hidden support
- [ ] `SettingsDialog`: Tambah switch "Checklist Groups: Default Tertutup"

### Sprint: Checklist Detail Pindah Seksi (Bagian 3)

- [ ] Identifikasi lokasi persis kode "Pindah Seksi" di `ChecklistControlPanel`
- [ ] Tambah state `_isSectionPickerExpanded` di widget relevan
- [ ] Bungkus daftar seksi dengan `AnimatedSize` + toggle bool
- [ ] Test: dialog tidak auto-close setelah memilih seksi

### Sprint: Task Master New Dashboard (Bagian 4A & 4B)

- [ ] `TodayTaskTile`: Ganti `Padding` terluar dengan `Container` ber-`decoration` kondisional
- [ ] `TodayTaskTile`: Gunakan `const Color(0xFFE8F5E9)` untuk state selesai, transparan untuk lainnya
- [ ] `DashboardSummaryCards`: Tambah parameter `todayTasksTotalCount`
- [ ] `DashboardSummaryCards`: Ubah nilai kartu ketiga menjadi `'$completedTargetsToday / $todayTasksTotalCount'`
- [ ] `DashboardSummaryCards`: Warna kartu ketiga dinamis (oranye / hijau tua)
- [ ] `TaskMasterNewScreen._buildSinglePaneReady`: Pass `todayTasks.length` ke `DashboardSummaryCards`
- [ ] `TaskMasterNewScreen._buildDesktopDashboard`: Sama seperti di atas
- [ ] Update semua test yang menyebut `DashboardSummaryCards` (tambah parameter baru)

---

*Dokumen ini final. Semua keputusan desain telah dikonfirmasi pengguna pada 2026-11-25.*
