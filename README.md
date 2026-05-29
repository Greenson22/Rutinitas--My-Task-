# Rutinitasku

A modern, offline-first productivity and task management application built with Flutter. Aplikasi ini dirancang untuk membantu Anda mengelola tugas harian, membangun rutinitas terstruktur melalui multi-hub checklist, serta melacak waktu produktif secara aman langsung dari perangkat Anda.

---

## 🚀 Fitur Utama

### 1. Task Master & Tipe Tugas Fleksibel
* **Manajemen Tugas Harian:** Kelola tugas berdasarkan kategori pilihan Anda dengan sistem hitungan (counter) harian yang mudah digunakan.
* **Tipe Tugas:** * *Tugas Biasa:* Untuk hitungan rutinitas atau checklist standar.
    * *Tugas Progress:* Dilengkapi dengan *Progress Bar* visual yang berubah warna secara dinamis (Merah ➔ Oranye ➔ Hijau ➔ Teal) sesuai dengan tingkat penyelesaian tugas.

### 2. My Checklist Hubs (Nested Structure)
* **Multi-Hub Kustom:** Kelompokkan berbagai kategori aktivitas ke dalam hub yang terpisah.
* **Struktur Bersarang (Nested Tree List):** Dukungan pengelolaan sub-materi dan sub-tugas yang dapat bercabang secara tak terbatas, memudahkan Anda menyusun rencana yang kompleks dan mendalam.

### 3. Jurnal Aktivitas & Sinkronisasi Otomatis
* **Pelacak Durasi Produktif:** Catat berapa lama waktu yang Anda habiskan untuk hal-hal bermanfaat setiap harinya.
* **Pipa Sinkronisasi Otomatis:** Setiap kali Anda menambah hitungan (*increment count*) pada fitur *Task Master*, sistem akan otomatis menambahkan durasi produktif sebanyak **+30 menit** ke dalam jurnal aktivitas Anda yang saling terhubung.

### 4. Analitik & Statistik Visual
* **Stacked Bar Chart:** Visualisasikan distribusi waktu produktif dan tren perkembangan harian Anda lewat grafik batang bertumpuk interaktif yang ramah perangkat mobile.
* **Filter Fleksibel:** Lihat riwayat produktivitas berdasarkan rentang waktu tertentu untuk mengevaluasi konsistensi Anda.

### 5. Data Center & Local Sharing (Keamanan 100% Offline)
* **Penyimpanan Lokal Mandiri:** Data Anda sepenuhnya milik Anda. Semua berkas disimpan di memori lokal perangkat pada subfolder khusus (`/mytask`, `/my_checklist`, `/jurnal_aktivitas`).
* **Backup & Restore Utama:** Ekspor data secara parsial (per fitur) dalam format JSON, atau kompres seluruh ekosistem data aplikasi menjadi satu berkas cadangan berbentuk **ZIP**.
* **Local Sharing (WebSocket):** Kirim dan terima data antar-perangkat secara instan dalam satu jaringan lokal (WiFi/LAN) menggunakan protokol komunikasi dua arah *Server-Client* tanpa memerlukan koneksi internet/cloud luar.
* **Kustomisasi Direktori:** Pengguna Android maupun Linux diberikan kebebasan penuh untuk memindahkan dan memilih folder penyimpanan data utama (*base directory*) sesuai preferensi.

### 6. UI Kustomisasi Adaptif
* **Bebas Pilih Warna:** Ubah warna latar belakang kartu materi menggunakan kode HEX kustom atau palet eksternal.
* **Adaptif & Kontras:** Sistem secara pintar akan mendeteksi tingkat kecerahan warna latar (*brightness estimation*), lalu otomatis menyesuaikan warna teks (Hitam/Putih) agar tetap nyaman dibaca.

---

## 🛠️ Teknologi yang Digunakan

* **Framework:** Flutter (Dart)
* **Arsitektur:** Clean Architecture / Feature-Driven Structure
* **Protokol Komunikasi:** WebSocket (Local Sharing)
* **Format Data:** JSON & ZIP Compression
* **Grafik:** Flutter Charting Library (Stacked Bar Chart)

---

## 📦 Cara Memulai

### Prasyarat
Sebelum memulai, pastikan Anda telah memasang:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) terbaru.
* Dart SDK yang sesuai.
* Android Studio / VS Code bersama ekstensi Flutter.

### Langkah Instalasi

1.  **Clone Repositori:**
    ```bash
    git clone [https://github.com/username/rutinitasku.git](https://github.com/username/rutinitasku.git)
    cd rutinitasku
    ```

2.  **Ambil Dependensi:**
    ```bash
    flutter pub get
    ```

3.  **Jalankan Aplikasi:**
    ```bash
    flutter run
    ```

---

## 🔒 Privasi & Keamanan
Aplikasi ini berjalan **100% secara offline**. Tidak ada data sensitif, riwayat tugas, atau catatan jurnal yang dikirim ke server luar. Fitur *Local Sharing* hanya membuka port lokal pada jaringan Wi-Fi Anda untuk komunikasi langsung antar-gawai milik Anda sendiri.