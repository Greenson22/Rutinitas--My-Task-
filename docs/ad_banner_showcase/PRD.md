# PRD — Ad Banner Showcase

| Field | Value |
|---|---|
| Produk | Rutinitasku |
| Nama Fitur | `ad_banner_showcase` |
| Versi Dokumen | 1.0 |
| Tanggal | 23 November 2026 |
| Status | Draft — siap untuk SPEC |
| Target Rilis | Eksperimental (opt-in via Settings) |
| Platform Utama | Android |
| Platform Pendukung | Linux desktop (iklan tidak tampil, layar tetap berfungsi) |

---

## 1. Ringkasan

**Ad Banner Showcase** adalah halaman baru yang menampilkan semua banner iklan yang tersebar di seluruh modul aplikasi — Task Master, MyChecklist, MyChecklist Detail, MyNote, MyNote Detail, MyPrompt, MyPrompt Detail, My Documents, dan Data Center — dalam satu tampilan bergulir vertikal (top-to-bottom).

Halaman ini dirancang untuk memudahkan pengujian iklan secara manual (QA, review placement) dan memberikan visibilitas penuh atas status pemuatan setiap slot iklan tanpa harus berpindah-pindah halaman. Karena sifatnya yang teknis/internal, fitur ini hanya dapat diakses melalui **pengaturan Fitur Eksperimental** di Settings Dialog — dan baru akan muncul di sidebar setelah toggle diaktifkan.

Selain itu, pengguna (atau developer) dapat mengatur **interval refresh** (berapa detik sebelum setiap slot iklan di-request ulang), sehingga perilaku iklan dapat diamati pada berbagai kondisi jaringan dan frekuensi refresh.

---

## 2. Latar Belakang

### 2.1 Kondisi Saat Ini

- Iklan banner sudah tersebar di 9 slot di berbagai halaman (lihat `AdService._productionAdUnitsAndroid`).
- Setiap banner menggunakan widget `AdaptiveBannerAd` yang dimuat secara independen saat halaman dibuka.
- Tidak ada cara tunggal untuk melihat semua banner sekaligus — tester harus buka setiap halaman satu per satu.
- Tidak ada kontrol atas kapan banner di-refresh; refresh hanya terjadi secara implisit saat widget dibuang dan dibuat ulang (navigasi).
- Random Generator sudah menggunakan pola yang sama: flag `enable_random_generator` di SharedPreferences, dibaca di `DrawerMenu`, diaktifkan dari Settings Dialog.

### 2.2 Masalah yang Diselesaikan

| Masalah | Dampak |
|---|---|
| Harus buka 9+ halaman untuk melihat semua slot iklan | QA lambat, placement sulit divalidasi |
| Tidak ada kontrol refresh interval | Tidak bisa simulasi skenario iklan bergilir / auto-refresh |
| Fitur debug/teknis tampil di menu utama | Mencemari UX pengguna akhir |

---

## 3. Tujuan dan Non-Goals

### Tujuan
- Menyediakan satu halaman yang menampilkan semua banner iklan berjajar vertikal.
- Memberikan kontrol refresh interval per siklus (misalnya: setiap 30–300 detik, atau bisa diatur manual).
- Menyembunyikan menu ini di balik toggle eksperimental agar tidak terlihat pengguna biasa.
- Mengikuti pola arsitektur yang sudah ada: `SharedPreferences` flag + `DrawerMenu` conditional + `SettingsDialog` toggle.

### Non-Goals
- **Bukan** halaman produksi yang diakses pengguna akhir secara rutin.
- **Bukan** pengganti AdMob dashboard untuk monitoring pendapatan iklan.
- **Bukan** implementasi iklan jenis baru (interstitial, rewarded, dll.) — hanya banner yang sudah ada.
- **Bukan** fitur cross-platform: iklan hanya tampil di Android. Di platform lain, layout tetap render (tanpa konten iklan).
- **Bukan** pengujian A/B placement; ini hanya untuk observasi teknis.

---

## 4. Pengguna dan Skenario

### Pengguna Primer
- **Developer / QA Internal**: mengaktifkan toggle eksperimental, membuka halaman untuk memverifikasi semua slot iklan dimuat dengan benar dan ukuran adaptif tepat.

### Pengguna Sekunder (opsional di masa depan)
- Pengguna yang ingin memahami placement iklan di aplikasi (transparency mode).

### Skenario Utama

**Skenario 1 — Aktivasi**
> Developer membuka Settings → bagian Fitur Eksperimental → mengaktifkan toggle "Ad Banner Showcase". Setelah dialog ditutup, menu "Ad Banner Showcase" muncul di sidebar. Developer membuka halaman, melihat semua banner berjajar dari atas ke bawah.

**Skenario 2 — Refresh Interval**
> Developer ingin menguji banner setiap 60 detik. Di dalam halaman Ad Banner Showcase, ia menyetel slider/input ke 60 detik. Halaman akan me-request ulang semua slot iklan setiap 60 detik — efek yang terlihat seperti "pindah halaman" tapi dalam satu layar.

**Skenario 3 — Nonaktivasi**
> Developer menutup Settings dan menonaktifkan toggle. Saat DrawerMenu di-refresh, menu "Ad Banner Showcase" menghilang dari sidebar.

---

## 5. Deskripsi Fitur

### 5.1 Layout Halaman

- Halaman memiliki `AppBar` dengan judul "Ad Banner Showcase" dan tombol back.
- Konten utama: `ListView` yang berisi slot-slot banner berjajar vertikal, dari atas ke bawah.
- Setiap slot memiliki:
  - **Label** nama slot (misalnya: "Task Master", "MyChecklist Hub", dll.)
  - **Widget banner** (`AdaptiveBannerAd` yang sudah ada)
  - **Divider** tipis antar slot
- Di bawah AppBar atau di atas daftar, terdapat kontrol **Refresh Interval**.

### 5.2 Urutan Slot Iklan (Top to Bottom)

| No. | Label | Ad Key |
|---|---|---|
| 1 | Task Master | `task_master_banner` |
| 2 | MyChecklist Hub | `checklist_hub_banner` |
| 3 | MyChecklist Detail | `checklist_detail_banner` |
| 4 | MyNote Hub | `note_hub_banner` |
| 5 | MyNote Detail | `note_detail_banner` |
| 6 | MyPrompt Hub | `prompt_hub_banner` |
| 7 | MyPrompt Detail | `prompt_detail_banner` |
| 8 | My Documents | `document_hub_banner` |
| 9 | Data Center | `data_center` |

> Catatan: `jurnal_activity_banner` ada di `AdService` tapi halaman Jurnal bukan dalam daftar permintaan fitur ini. Dapat ditambahkan sebagai entri ke-10 jika diinginkan.

### 5.3 Kontrol Refresh Interval

- Tersedia di dalam halaman (bukan di Settings global).
- Nilai default: **60 detik** (aman, tidak terlalu agresif untuk AdMob quota).
- Rentang yang bisa dipilih: **30 detik – 300 detik** (dengan step 30 detik), atau input manual.
- Nilai interval disimpan di **SharedPreferences** dengan key `ad_showcase_refresh_interval_seconds` agar persisten antar sesi.
- Saat timer mencapai interval, semua slot iklan di-dispose dan dibuat ulang (setState rebuild seluruh daftar).
- Countdown timer kecil dapat ditampilkan di UI agar pengguna tahu kapan refresh berikutnya.

### 5.4 Mekanisme Eksperimental

Mengikuti pola `enable_random_generator`:

| Aspek | Detail |
|---|---|
| SharedPreferences key | `enable_ad_banner_showcase` |
| Default value | `false` |
| Toggle ada di | Settings Dialog → bagian "Fitur Eksperimental" |
| Dibaca di | `DrawerMenu._checkAdShowcaseVisibility()` |
| Menu hilang/muncul | Setelah Settings Dialog ditutup (via `.then(_checkAllMenuVisibility)`) |

---

## 6. Persyaratan Non-Fungsional

| Aspek | Persyaratan |
|---|---|
| Platform | Menu dan halaman hanya berfungsi optimal di Android. Di desktop/web, halaman tetap render tapi banner mengembalikan `SizedBox.shrink()`. |
| Performa | Dispose dan reload iklan hanya saat interval tercapai, bukan setiap frame. |
| Quota AdMob | Interval minimum 30 detik untuk menghindari permintaan berlebih yang melanggar kebijakan AdMob. |
| Keamanan | Tidak ada data pengguna yang dikirim ke server baru. Semua hanya menggunakan AdMob SDK yang sudah ada. |
| State Persistence | Interval refresh tersimpan di SharedPreferences. Status iklan dimuat ulang saat halaman dibuka kembali. |

---

## 7. Keputusan Desain Terbuka

| # | Pertanyaan | Opsi |
|---|---|---|
| D1 | Apakah `jurnal_activity_banner` perlu disertakan? | Ya (tambah sebagai slot ke-10) / Tidak (di luar scope) |
| D2 | Mekanisme refresh: dispose semua sekaligus atau rolling refresh per slot? | Sekaligus (lebih mudah diimplementasikan) / Rolling (lebih halus tapi kompleks) |
| D3 | Apakah interval disimpan per-device atau hardcode default saja? | SharedPreferences (lebih fleksibel, sudah dipilih di PRD ini) / Hardcode |
| D4 | Label di atas banner: label teks saja atau card penuh dengan status (loaded/failed)? | Label teks saja (sederhana) / Card dengan status (lebih informatif untuk QA) |

---

## 8. Kriteria Keberhasilan

- [ ] Toggle di Settings Dialog dapat mengaktifkan/menonaktifkan menu di sidebar tanpa restart app.
- [ ] Halaman menampilkan semua 9 (atau 10) slot banner berjajar vertikal.
- [ ] Semua banner yang sudah berjalan di halaman aslinya juga berhasil dimuat di showcase.
- [ ] Interval refresh bisa diatur dan timer berjalan dengan benar.
- [ ] Di platform non-Android, halaman tidak crash.
- [ ] Pola kode konsisten dengan fitur Random Generator yang sudah ada.
