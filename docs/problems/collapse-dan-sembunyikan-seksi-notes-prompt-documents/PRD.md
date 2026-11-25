# PRD: Collapse & Sembunyikan Seksi — MyNotes, MyPrompt, MyDocuments

> **Status:** Draft  
> **Tanggal:** 2026-11-25  
> **Fitur Target:** MyNotes · MyPrompt · MyDocuments  
> **Referensi Existing:** Checklist Groups (`daily_controller.dart`, `checklist_screen.dart`), `grouped_section_layout.dart`, `interactive_section_header.dart`, `settings_dialog.dart`

---

## 1. Problem Statement

Halaman utama MyNotes, MyPrompt, dan MyDocuments menampilkan seluruh seksi beserta kartu grupnya secara terbuka setiap kali dibuka. Ketika pengguna memiliki banyak seksi (misalnya KULIAH, KERJA, ARSIP, PRIBADI), tampilan menjadi panjang dan padat. Tidak ada cara untuk:

1. **Melipat (collapse)** sebuah seksi yang sementara tidak dibutuhkan agar tampilan lebih fokus.
2. **Menyimpan** kondisi lipatan tersebut sehingga saat aplikasi dibuka kembali, tampilan kembali seperti yang terakhir diatur.
3. **Menyembunyikan secara permanen** sebuah seksi beserta seluruh isinya dari tampilan utama, dan memperlihatkannya kembali hanya ketika tombol mata ditekan.

Checklist sudah memiliki kedua fitur ini. Notes, Prompt, dan Documents tertinggal.

---

## 2. Solution

Tambahkan dua fitur saling melengkapi pada layar utama (layar grup/seksi) dari ketiga fitur:

### 2.1 Collapse Seksi (Lipat/Buka)
- Setiap header seksi bisa di-tap untuk melipat atau membuka isinya (kartu-kartu grup di bawahnya), dengan animasi `AnimatedCrossFade` yang sudah ada di `GroupedSectionLayout`.
- State terlipat/terbuka per seksi disimpan di **SharedPreferences** menggunakan key yang berbeda per fitur (misalnya `notes_collapsed_sections`, `prompt_collapsed_sections`, `docs_collapsed_sections`).
- Perilaku default dan persistensi dikontrol oleh pengaturan global di **Settings Dialog**.

### 2.2 Sembunyikan Seksi (Section Hidden)
- Di mode edit header seksi, tombol mata (`visibility`/`visibility_off`) dapat digunakan untuk menyembunyikan atau menampilkan sebuah seksi.
- Seksi yang disembunyikan **tidak muncul** di tampilan utama, termasuk header dan seluruh kartu grupnya.
- State tersembunyi disimpan di **SharedPreferences** (bukan di file JSON data), menggunakan key terpisah per fitur (misalnya `notes_hidden_sections`, `prompt_hidden_sections`, `docs_hidden_sections`).
- Tombol mata (👁) di AppBar toggle global: tap sekali tampilkan semua seksi yang di-hidden, tap lagi sembunyikan kembali.

---

## 3. User Stories

1. Sebagai pengguna MyNotes, saya ingin bisa menekan header seksi untuk melipat kartu-kartu grupnya, agar tampilan lebih ringkas saat saya sedang fokus pada seksi tertentu.
2. Sebagai pengguna MyPrompt, saya ingin kondisi lipatan seksi saya tetap tersimpan saat keluar dan kembali ke aplikasi, agar saya tidak perlu mengatur ulang setiap sesi.
3. Sebagai pengguna MyDocuments, saya ingin bisa mengatur lewat Settings bahwa semua seksi mulai dalam kondisi tertutup secara default, agar tampilan selalu bersih saat membuka aplikasi.
4. Sebagai pengguna, saya ingin ada opsi di Settings untuk menonaktifkan persistensi lipatan, sehingga setiap kali buka aplikasi semua seksi kembali ke kondisi default (terbuka).
5. Sebagai pengguna MyNotes, saya ingin bisa menyembunyikan seksi yang jarang dipakai (misalnya ARSIP LAMA) dari tampilan utama, agar saya bisa fokus pada seksi aktif.
6. Sebagai pengguna MyPrompt, saya ingin seksi yang disembunyikan tetap tersembunyi walau saya keluar dan masuk kembali ke aplikasi.
7. Sebagai pengguna MyDocuments, saya ingin menekan ikon mata (👁) di AppBar untuk memperlihatkan semua seksi yang tersembunyi sekaligus, agar saya bisa mengaksesnya ketika dibutuhkan.
8. Sebagai pengguna, saya ingin saat sebuah seksi diperlihatkan kembali lewat tombol mata di AppBar, seksi tersebut muncul dalam kondisi collapse/expand sesuai state terakhirnya (bukan dipaksa terbuka).
9. Sebagai pengguna, saya ingin ikon mata di header seksi (saat edit mode) menampilkan badge "Tersembunyi" di samping nama seksi (seperti perilaku `InteractiveSectionHeader` yang sudah ada), agar saya tahu mana yang disembunyikan.
10. Sebagai pengguna, saya ingin pengaturan collapse ini berlaku seragam untuk Notes, Prompt, dan Documents tanpa perlu mengatur satu per satu, agar konsisten.
11. Sebagai pengguna, saya ingin ikon chevron (▶/▼) muncul di kiri nama seksi sebagai indikator visual apakah seksi sedang terlipat atau terbuka, agar mudah dibaca sekilas.
12. Sebagai pengguna, saya ingin state hidden seksi **tidak** mengubah file JSON data saya, agar portabilitas data tetap terjaga (saat data dipindahkan ke perangkat lain, semua grup tetap terlihat).

---

## 4. Domain Model

### 4.1 Glosarium

| Istilah | Definisi |
|---|---|
| **Seksi** | Kelompok header yang menampung kartu-kartu grup. Di Notes: `sectionName` pada `NoteGroup`. Di Prompt: `sectionName` pada `PromptGroup`. Di Documents: `sectionCategory` pada `DocumentGroup`. |
| **Grup** | Unit kartu individual di dalam sebuah seksi. Masing-masing grup memiliki file JSON tersendiri di storage. |
| **Collapse** | Kondisi seksi di mana konten kartu-kartunya tersembunyi di bawah header dengan animasi lipat. Header tetap terlihat. |
| **Section Hidden** | Kondisi seksi di mana header DAN seluruh kartu grupnya tidak ditampilkan sama sekali. Hanya bisa diperlihatkan via tombol mata global di AppBar. |
| **State Lipatan** | Peta dari nama seksi ke boolean `isCollapsed`, disimpan di SharedPreferences per fitur. |
| **State Tersembunyi** | Daftar nama seksi yang di-hidden, disimpan di SharedPreferences per fitur. Terpisah dari `isHidden` di model grup. |
| **Mode Tampil Hidden** | State boolean di controller (setara `showHiddenSection` di Documents) yang dikontrol tombol mata AppBar. |
| **Settings Dialog** | Dialog pengaturan global aplikasi (`settings_dialog.dart`) tempat preferensi collapse dikonfigurasi. |

### 4.2 SharedPreferences Keys

| Key | Tipe | Default | Keterangan |
|---|---|---|---|
| `sections_default_collapsed` | `bool` | `false` | Jika `true`, semua seksi di Notes/Prompt/Docs mulai dalam kondisi terlipat. Berlaku global. |
| `sections_remember_collapse_state` | `bool` | `true` | Jika `true`, state lipatan per seksi dipersisten. Jika `false`, setiap buka app ikuti default. |
| `notes_collapsed_sections` | `String` (JSON list) | `[]` | Daftar nama seksi di Notes yang sedang terlipat. |
| `prompt_collapsed_sections` | `String` (JSON list) | `[]` | Daftar nama seksi di Prompt yang sedang terlipat. |
| `docs_collapsed_sections` | `String` (JSON list) | `[]` | Daftar nama seksi di Documents yang sedang terlipat. |
| `notes_hidden_sections` | `String` (JSON list) | `[]` | Daftar nama seksi di Notes yang disembunyikan. |
| `prompt_hidden_sections` | `String` (JSON list) | `[]` | Daftar nama seksi di Prompt yang disembunyikan. |
| `docs_hidden_sections` | `String` (JSON list) | `[]` | Daftar nama seksi di Documents yang disembunyikan. |

### 4.3 State Machine Seksi

```
                    ┌──────────────────────────────────┐
                    │          VISIBLE + EXPANDED       │◄──────────────────┐
                    │  (normal, kartu tampil semua)     │                   │
                    └──────────┬──────────────┬─────────┘                   │
                               │              │                             │
                          tap header     tap 👁 edit mode             tap header
                               │              │                             │
                               ▼              ▼                             │
              ┌─────────────────────┐  ┌─────────────────────┐             │
              │ VISIBLE + COLLAPSED │  │  HIDDEN (section)   │◄────────────┘
              │ (header tampil,     │  │  (header + konten   │  tap 👁 AppBar
              │  konten tersembunyi)│  │   tidak tampil sama │  (showHiddenSection=true)
              └──────────┬──────────┘  │   sekali)           │
                         │            └──────────────────────┘
                    tap header
                         │
                         ▼
              ┌─────────────────────┐
              │ VISIBLE + EXPANDED  │
              └─────────────────────┘
```

### 4.4 Komponen yang Terlibat

```
GroupedSectionLayout<T>
  ├── isSectionCollapsed: bool Function(String sectionKey)?  ← sudah ada
  ├── [BARU] isSectionHidden: bool Function(String sectionKey)?
  └── [BARU] visibleSectionKeys: computed dari sectionKeys - hiddenSections

InteractiveSectionHeader
  ├── onToggleCollapse: VoidCallback?  ← sudah ada
  ├── isCollapsed: bool?               ← sudah ada
  ├── onToggleVisibility: VoidCallback? ← sudah ada (digunakan checklist)
  └── isHidden: bool?                  ← sudah ada

SectionCollapseService (BARU)
  ├── loadCollapsedSections(featureKey) → Set<String>
  ├── saveCollapsedSections(featureKey, Set<String>)
  ├── loadHiddenSections(featureKey) → Set<String>
  ├── saveHiddenSections(featureKey, Set<String>)
  ├── isRememberEnabled() → bool
  └── isDefaultCollapsed() → bool

NotesScreen / PromptScreen / MyDocumentsScreen
  ├── _collapsedSections: Set<String>  ← BARU
  ├── _hiddenSections: Set<String>     ← BARU
  ├── _showHiddenSection: bool         ← sudah ada di Notes & Prompt, perluas ke Sections
  ├── _toggleSectionCollapse(sectionKey)
  └── _toggleSectionHidden(sectionKey)
```

---

## 5. Implementation Decisions

### 5.1 Storage Layer
- State collapse dan hidden seksi disimpan di SharedPreferences **bukan** di file JSON data grup. Ini memastikan file data tetap portable dan tidak berubah saat hanya mengubah tampilan.
- Key penyimpanan bersifat **per-fitur** (prefix: `notes_`, `prompt_`, `docs_`) agar Notes yang di-collapse tidak mempengaruhi state Prompt.
- Dua key **global** (`sections_default_collapsed` dan `sections_remember_collapse_state`) berlaku untuk ketiga fitur sekaligus (konsisten dengan pengaturan Checklist yang sudah ada).

### 5.2 Collapse Behavior
- Collapse hanya ada di **layar utama** (layar seksi/grup), bukan di layar detail grup.
- Tap pada header seksi akan toggle `isCollapsed`. Efek visual menggunakan `AnimatedCrossFade` yang sudah tersedia di `GroupedSectionLayout`.
- Jika `sections_remember_collapse_state = true`: state disimpan ke SharedPreferences setiap kali ada perubahan, dimuat kembali saat `initState`.
- Jika `sections_remember_collapse_state = false`: state hanya di memori, diinisialisasi dari `sections_default_collapsed`.
- Ikon chevron (`Icons.chevron_right` / `Icons.expand_more`) sudah didukung oleh `InteractiveSectionHeader` via properti `isCollapsed` dan `onToggleCollapse`.

### 5.3 Section Hidden Behavior
- State hidden seksi disimpan di SharedPreferences sebagai JSON list of String (nama seksi).
- Disimpan persisten antar sesi.
- Saat `showHiddenSection = false` (default): seksi hidden tidak muncul sama sekali di layar.
- Saat `showHiddenSection = true`: seksi hidden dimunculkan dengan visual berbeda (badge "Tersembunyi" dari `InteractiveSectionHeader` yang sudah ada).
- Tombol mata di AppBar menggunakan `additionalAction` di `GroupedSectionLayout` (pola yang sama dengan MyDocuments yang sudah ada).
- `InteractiveSectionHeader` sudah mendukung `onToggleVisibility` dan `isHidden` — cukup dihubungkan ke state seksi yang baru (bukan ke state grup).

### 5.4 Interaksi Collapse × Hidden
- Jika seksi A di-hidden SAAT collapse, saat diperlihatkan kembali lewat tombol mata, seksi A tetap dalam kondisi terlipat (state collapse dipertahankan).
- Tombol mata AppBar hanya mengubah `showHiddenSection`, tidak menyentuh state collapse.

### 5.5 Settings Dialog
- Tambah section baru **"Tampilan Sections (Notes, Prompt, Dokumen)"** di bawah section "Tampilan Checklist" yang sudah ada.
- Dua toggle baru:
  1. **"Tutup seksi secara default"** → `sections_default_collapsed` (default: `false`)
  2. **"Ingat status lipatan seksi"** → `sections_remember_collapse_state` (default: `true`)
- Handler mengikuti pola `_handleSectionDefaultCollapsedToggle` dan `_handleSectionRememberCollapseStateToggle` yang sudah ada di `SettingsDialog`.

### 5.6 Refactoring GroupedSectionLayout
- Tambah parameter opsional `isSectionHidden: bool Function(String sectionKey)?` ke `GroupedSectionLayout`.
- Saat `isSectionHidden` terdefinisi dan mengembalikan `true` untuk sebuah seksi, seksi tersebut tidak dirender (di-skip dalam `ListView.builder`), kecuali jika caller memutuskan untuk memasukkan seksi hidden ke `sectionKeys` saat `showHiddenSection = true`.
- Pola ini sudah ada di Documents (memasukkan `_hidden_key` ke `sectionKeys`); perlu distandarisasi.

### 5.7 Ekstraksi Service (Opsional, Disarankan)
- Buat `SectionStateService` (atau cukup helper function di `SharedPreferences`) untuk memusatkan logika baca/tulis state collapse dan hidden per fitur.
- Ini mencegah duplikasi kode yang sama di tiga controller (NotesScreen, PromptController, DocumentsController).

---

## 6. Testing Decisions

### 6.1 Prinsip Pengujian
- Uji **behavior yang terlihat** dari luar (state berubah, SharedPreferences tersimpan), bukan implementasi internal widget.
- Gunakan `SharedPreferences.setMockInitialValues` untuk tes unit state service.
- Gunakan widget test minimal (pump widget, tap header, verifikasi state) mengikuti pola test yang sudah ada di `test/features/checklist/presentation/checklist_section_collapse_ticket_05_test.dart`.

### 6.2 Modul yang Diuji
1. **SectionStateService** — unit test untuk load/save collapsed sections dan hidden sections per fitur key.
2. **NotesScreen** — widget test: tap header → collapse, state tersimpan ke SharedPreferences.
3. **PromptController** — unit test: toggle collapse/hidden section, verifikasi state.
4. **DocumentsController** — unit test: toggle hidden section persisten.
5. **SettingsDialog** — unit test: toggle `sections_default_collapsed` dan `sections_remember_collapse_state` tersimpan ke SharedPreferences.
6. **GroupedSectionLayout** — widget test: seksi hidden tidak dirender, seksi visible + collapsed tidak tampilkan konten.

### 6.3 Prior Art
- `test/core/presentation/widgets/settings_dialog_checklist_groups_collapse_test.dart`
- `test/features/checklist/presentation/checklist_section_collapse_ticket_05_test.dart`
- `test/features/checklist/daily_controller_section_state_test.dart`

---

## 7. Out of Scope

- Collapse di **layar detail** (di dalam satu grup: detail catatan, detail prompt, detail dokumen). Hanya layar utama (layar grup/seksi) yang termasuk.
- Menyembunyikan **grup individual** (sudah ada lewat `isHidden` di model grup dan popup menu pada kartu).
- Reorder seksi yang disembunyikan (cukup sembunyikan/tampilkan saja).
- Collapse atau sembunyikan seksi di fitur lain (Checklist Detail, Task Master, Jurnal Aktivitas).
- Sinkronisasi state collapse/hidden ke cloud atau antar perangkat.
- Animasi khusus berbeda dari `AnimatedCrossFade` yang sudah ada.

---

## 8. Further Notes

- **MyDocuments sudah punya `showHiddenSection`** di controller-nya, tapi itu untuk grup, bukan seksi. Pastikan tidak terjadi konflik naming.
- **InteractiveSectionHeader** sudah mendukung `onToggleVisibility` dan `isHidden` tapi di checklist digunakan untuk grup di dalam seksi (level berbeda). Reuse properti ini untuk seksi-level hidden.
- **Notes tidak menggunakan controller terpisah** (bisnis logic ada langsung di `_NotesScreenState`). Pertimbangkan apakah logika collapse/hidden perlu diekstrak ke `NoteController` agar konsisten dengan Prompt dan Documents.
- **Urutan key SharedPreferences** harus didokumentasikan agar tidak bertabrakan dengan key checklist yang sudah ada (`section_default_collapsed`, `section_remember_collapse_state`, `checklist_groups_default_collapsed`).
- Tambahkan `docs/adr/collapse-seksi-notes-prompt-docs.md` jika keputusan arsitektur ini perlu dicatat secara formal.
