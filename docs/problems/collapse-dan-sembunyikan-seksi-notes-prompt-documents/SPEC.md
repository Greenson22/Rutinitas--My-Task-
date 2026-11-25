# SPEC — Collapse & Sembunyikan Seksi (MyNotes, MyPrompt, MyDocuments)

| Field | Value |
|---|---|
| Fitur | `collapse_section_notes_prompt_docs` |
| Sumber | `docs/problems/collapse-dan-sembunyikan-seksi-notes-prompt-documents/PRD.md` |
| Status | Ready for agent |
| Tanggal | 2026-11-25 |
| Platform utama | Android dan Linux desktop |

---

## Problem Statement

Halaman utama MyNotes, MyPrompt, dan MyDocuments menampilkan seluruh seksi beserta kartu grupnya secara terbuka setiap kali dibuka. Ketika pengguna memiliki banyak seksi (misalnya KULIAH, KERJA, ARSIP, PRIBADI), tampilan menjadi panjang dan padat. Tidak ada cara untuk melipat seksi yang sementara tidak dibutuhkan, menyimpan kondisi lipatan tersebut antar sesi, atau menyembunyikan secara permanen seksi yang jarang dipakai. Checklist sudah memiliki kedua fitur ini. Notes, Prompt, dan Documents tertinggal.

---

## Solution

Tambahkan dua fitur saling melengkapi pada layar utama (layar grup/seksi) dari ketiga fitur:

**Collapse seksi:** Setiap header seksi bisa di-tap untuk melipat atau membuka kartu-kartu grup di bawahnya dengan animasi. State terlipat/terbuka per seksi disimpan di SharedPreferences menggunakan key terpisah per fitur dan dikontrol oleh pengaturan global di Settings Dialog.

**Sembunyikan seksi:** Di mode edit header, tombol mata menyembunyikan seluruh seksi (header + konten). Seksi yang disembunyikan tidak muncul sama sekali kecuali tombol mata di AppBar ditekan untuk toggle global. State hidden disimpan di SharedPreferences per fitur, tidak mengubah file JSON data model.

---

## User Stories

1. Sebagai pengguna MyNotes, saya ingin bisa menekan header seksi untuk melipat kartu-kartu grupnya, agar tampilan lebih ringkas saat saya sedang fokus pada seksi tertentu.
2. Sebagai pengguna MyPrompt, saya ingin kondisi lipatan seksi tersimpan saat keluar dan kembali ke aplikasi, agar saya tidak perlu mengatur ulang setiap sesi.
3. Sebagai pengguna MyDocuments, saya ingin mengatur lewat Settings bahwa semua seksi mulai dalam kondisi tertutup secara default, agar tampilan selalu bersih saat membuka aplikasi.
4. Sebagai pengguna, saya ingin ada opsi di Settings untuk menonaktifkan persistensi lipatan, sehingga setiap buka aplikasi semua seksi kembali ke kondisi default (terbuka atau tertutup sesuai setting).
5. Sebagai pengguna MyNotes, saya ingin bisa menyembunyikan seksi yang jarang dipakai dari tampilan utama, agar saya bisa fokus pada seksi aktif.
6. Sebagai pengguna MyPrompt, saya ingin seksi yang disembunyikan tetap tersembunyi walau saya keluar dan masuk kembali ke aplikasi.
7. Sebagai pengguna MyDocuments, saya ingin menekan ikon mata (👁) di AppBar untuk memperlihatkan semua seksi yang tersembunyi sekaligus, agar saya bisa mengaksesnya ketika dibutuhkan.
8. Sebagai pengguna, saya ingin saat sebuah seksi diperlihatkan kembali lewat tombol mata di AppBar, seksi tersebut muncul dalam kondisi collapse/expand sesuai state terakhirnya (bukan dipaksa terbuka).
9. Sebagai pengguna, saya ingin ikon mata di header seksi (saat edit mode) menampilkan badge "Tersembunyi" di samping nama seksi, agar saya tahu mana yang disembunyikan.
10. Sebagai pengguna, saya ingin pengaturan collapse ini berlaku seragam untuk Notes, Prompt, dan Documents tanpa perlu mengatur satu per satu, agar konsisten.
11. Sebagai pengguna, saya ingin ikon chevron (▶/▼) muncul di kiri nama seksi sebagai indikator visual apakah seksi sedang terlipat atau terbuka.
12. Sebagai pengguna, saya ingin state hidden seksi tidak mengubah file JSON data saya, agar portabilitas data tetap terjaga.
13. Sebagai pengguna, saya ingin seksi yang disembunyikan tidak memengaruhi seksi lain — melipat atau memperlihatkan seksi A tidak mengubah state seksi B.
14. Sebagai pengguna, saya ingin state hidden seksi berbeda dari state hidden grup individual, agar kedua mekanisme bisa dipakai bersamaan tanpa konflik.

---

## Implementation Decisions

### Storage

1. State collapse per seksi disimpan di SharedPreferences sebagai JSON list of String (nama seksi yang sedang terlipat), dengan key terpisah per fitur: `notes_collapsed_sections`, `prompt_collapsed_sections`, `docs_collapsed_sections`.
2. State hidden per seksi disimpan di SharedPreferences sebagai JSON list of String (nama seksi yang disembunyikan), dengan key terpisah per fitur: `notes_hidden_sections`, `prompt_hidden_sections`, `docs_hidden_sections`.
3. State ini tidak ditulis ke file JSON data grup. `NoteGroup.isHidden`, `PromptGroup.isHidden`, dan `DocumentGroup.isHidden` yang sudah ada tidak disentuh — ketiganya untuk menyembunyikan grup individual, bukan seksi.
4. Dua key global berlaku seragam untuk ketiga fitur: `sections_default_collapsed` (default: `false`) dan `sections_remember_collapse_state` (default: `true`). Key ini terpisah dari key checklist yang sudah ada (`section_default_collapsed`, `section_remember_collapse_state`, `checklist_groups_default_collapsed`).

### Collapse Behavior

5. Collapse hanya ada di layar utama (layar seksi/grup), bukan layar detail grup.
6. Tap pada header seksi toggle state `isCollapsed` untuk seksi tersebut. Efek visual menggunakan `AnimatedCrossFade` yang sudah ada di `GroupedSectionLayout`.
7. Jika `sections_remember_collapse_state = true`: set collapsed sections disimpan ke SharedPreferences setiap kali ada perubahan, dimuat kembali di `initState`.
8. Jika `sections_remember_collapse_state = false`: state hanya di memori runtime, diinisialisasi dari `sections_default_collapsed` tanpa membaca riwayat sebelumnya.
9. `InteractiveSectionHeader` sudah mendukung properti `onToggleCollapse` dan `isCollapsed` beserta ikon chevron — cukup dihubungkan ke state seksi baru tanpa perubahan widget ini.

### Section Hidden Behavior

10. Di mode edit header seksi, tombol mata (`onToggleVisibility`) menyembunyikan atau menampilkan seksi. `InteractiveSectionHeader` sudah mendukung properti `onToggleVisibility` dan `isHidden` beserta badge "Tersembunyi" — cukup dihubungkan.
11. Saat `showHiddenSection = false` (default): seksi hidden tidak dirender sama sekali di `ListView.builder`.
12. Saat `showHiddenSection = true`: seksi hidden dimasukkan ke `sectionKeys` dengan suffix `_hidden_key` (pola yang sudah ada di Documents) dan ditampilkan dengan visual berbeda.
13. Tombol mata di AppBar menggunakan slot `additionalAction` di `GroupedSectionLayout` — pola identik dengan `toggleShowHiddenSection` di DocumentsController.
14. Toggle `showHiddenSection` tidak mengubah state collapse; saat seksi muncul kembali, ia tampil sesuai state collapse terakhirnya.

### Settings Dialog

15. Tambah bagian baru **"Tampilan Sections (Notes, Prompt, Dokumen)"** di bawah bagian "Tampilan Checklist" yang sudah ada di `SettingsDialog`.
16. Dua toggle baru mengikuti pola handler yang sudah ada:
    - **"Tutup seksi secara default"** → key `sections_default_collapsed`, default `false`.
    - **"Ingat status lipatan seksi"** → key `sections_remember_collapse_state`, default `true`.

### Modifikasi Layar

17. `NotesScreen` (`_NotesScreenState`) mendapat dua set baru: `_collapsedSections` dan `_hiddenSections`, plus boolean `_showHiddenSections`. Logika baca/tulis SharedPreferences ditambahkan di `initState` dan setiap toggle.
18. `PromptController` mendapat dua set baru: `collapsedSections` dan `hiddenSections`, plus boolean `showHiddenSections`. Controller memanggil SharedPreferences langsung (pola yang sama dengan `localEmptySections`).
19. `DocumentsController` sudah punya `showHiddenSection` untuk grup. Tambah `collapsedSections: Set<String>` dan `hiddenSections: Set<String>` khusus untuk seksi, dengan penamaan yang tidak bentrok.
20. Ketiga layar mengoper `isSectionCollapsed: (key) => _collapsedSections.contains(key)` ke `GroupedSectionLayout` yang sudah mendukung parameter ini.
21. Ketiga layar memfilter `sectionKeys` berdasarkan `_hiddenSections` sebelum meneruskannya ke `GroupedSectionLayout` (atau memasukkan `_hidden_key` saat `showHiddenSections = true`).

### State Machine Seksi (dari PRD)

```
VISIBLE + EXPANDED  <──tap header──>  VISIBLE + COLLAPSED
       │                                       │
   tap 👁 edit                             tap 👁 edit
       │                                       │
       ▼                                       ▼
  HIDDEN (tidak tampil sama sekali)
       │
  tap 👁 AppBar (showHiddenSections = true)
       │
       ▼
  Muncul kembali sesuai state collapse terakhir
```

---

## Testing Decisions

### Prinsip

Test yang baik menguji perilaku eksternal melalui antarmuka publik: state SharedPreferences berubah setelah aksi UI, kartu grup tidak tampil saat seksi terlipat, header tidak tampil saat seksi hidden dan tombol mata AppBar belum ditekan. Test tidak bergantung pada nama method privat atau detail implementasi widget internal.

### Seam Pengujian

Seam utama yang diusulkan adalah **layar (screen)** itu sendiri — `NotesScreen`, `PromptScreen`, dan `MyDocumentsScreen` — dipump sebagai widget dengan `SharedPreferences.setMockInitialValues` dan data fixture minimal. Ini adalah seam tertinggi yang bisa dipakai tanpa menyentuh file system nyata.

Seam ini dipilih karena:
- Sudah dipakai oleh test collapse checklist yang ada di repositori.
- Ketiga layar mengandung seluruh logika state collapse dan hidden (tidak terdistribusi di banyak layer).
- Tidak membutuhkan mock infrastructure baru.

Seam kedua adalah **`SettingsDialog`** — dipump langsung, tap switch, verifikasi SharedPreferences. Seam ini sudah dipakai oleh `settings_dialog_checklist_groups_collapse_test.dart`.

### Modul yang Diuji

- **`SettingsDialog`** — toggle dua switch baru (`sections_default_collapsed`, `sections_remember_collapse_state`) menyimpan key yang benar ke SharedPreferences tanpa mengubah key checklist yang sudah ada.
- **`NotesScreen`** — tap header seksi melipat konten; state tersimpan ke `notes_collapsed_sections`; tap tombol mata di edit mode mengubah `notes_hidden_sections`; tombol mata AppBar toggle `showHiddenSections`.
- **`PromptScreen`** — perilaku identik dengan Notes tetapi key `prompt_collapsed_sections` dan `prompt_hidden_sections`.
- **`MyDocumentsScreen`** — perilaku identik dengan Notes tetapi key `docs_collapsed_sections` dan `docs_hidden_sections`; pastikan tidak bertabrakan dengan `showHiddenSection` untuk grup yang sudah ada.

### Skenario Test Wajib

- `sections_default_collapsed = true` → semua seksi di Notes/Prompt/Docs dimulai terlipat saat layar dibuka.
- `sections_default_collapsed = false` → semua seksi dimulai terbuka.
- `sections_remember_collapse_state = true` → tap collapse → `notes_collapsed_sections` di SharedPreferences memuat nama seksi tersebut.
- `sections_remember_collapse_state = false` → tap collapse → `notes_collapsed_sections` tidak berubah (state hanya di memori).
- Tap header seksi yang terlipat → kartu grup di bawahnya muncul; ikon chevron berubah dari `chevron_right` ke `expand_more`.
- Tap header seksi yang terbuka → kartu grup hilang; ikon chevron berubah dari `expand_more` ke `chevron_right`.
- Tap tombol mata di edit mode seksi → seksi tidak tampil saat `showHiddenSections = false`; `notes_hidden_sections` di SharedPreferences memuat nama seksi tersebut.
- Tap tombol mata AppBar → seksi hidden muncul dengan visual berbeda (badge "Tersembunyi" atau label `_hidden_key`); tap lagi → seksi hilang kembali.
- Seksi yang di-hidden sebelum terlipat → saat diperlihatkan kembali lewat tombol mata AppBar, seksi tampil dalam kondisi terlipat (ikon `chevron_right`), konten kartu tidak tampil.
- State hidden seksi tidak mempengaruhi `NoteGroup.isHidden` / `PromptGroup.isHidden` / `DocumentGroup.isHidden` (grup individual tetap pada state aslinya).
- Key checklist yang sudah ada (`section_default_collapsed`, `section_remember_collapse_state`, `checklist_groups_default_collapsed`) tidak berubah saat toggle setting baru.

### Prior Art

- `test/core/presentation/widgets/settings_dialog_checklist_groups_collapse_test.dart`
- `test/features/checklist/presentation/checklist_section_collapse_ticket_05_test.dart`
- `test/features/checklist/daily_controller_section_state_test.dart`
- `test/features/checklist/presentation/checklist_section_hide_ticket_03_test.dart`

---

## Out of Scope

- Collapse di layar detail grup (detail catatan, detail prompt, detail dokumen). Hanya layar utama.
- Menyembunyikan grup individual (sudah ada lewat `isHidden` di model dan popup menu kartu).
- Reorder seksi yang disembunyikan.
- Collapse atau sembunyikan seksi di fitur lain (Checklist Detail, Task Master, Jurnal Aktivitas).
- Sinkronisasi state collapse/hidden ke cloud atau antar perangkat.

---

## Further Notes

- **DocumentsController** sudah punya `showHiddenSection` (boolean) untuk grup individual. Naming untuk fitur baru di Documents harus berbeda — gunakan `showHiddenSections` (jamak) atau `showHiddenMainSections` untuk membedakan dari yang sudah ada.
- **Notes tidak memiliki controller terpisah** — bisnis logic ada langsung di `_NotesScreenState`. Jika di masa depan Notes diekstrak ke `NoteController`, logika collapse/hidden perlu dipindahkan juga. Untuk spec ini, implementasi langsung di state sudah cukup.
- **`GroupedSectionLayout`** sudah mendukung `isSectionCollapsed` via callback. Tidak ada perubahan pada widget ini yang diperlukan untuk fitur collapse. Filtering seksi hidden dilakukan sebelum data diteruskan ke layout (di layar masing-masing), mengikuti pola yang sudah ada di Documents dan PromptScreen.
- Repositori ini belum memiliki konfigurasi issue tracker. Spec ini disimpan sebagai dokumen lokal. Jika ingin dipublikasikan ke tracker dengan label `ready-for-agent`, jalankan `/setup-matt-pocock-skills` terlebih dahulu.
