## Aturan Pengujian (Testing) Flutter

- **Larangan:** JANGAN gunakan `flutter test` untuk memverifikasi fitur, alur aplikasi, atau tampilan UI.
- **Pemilihan Perangkat Otomatis (Wajib):** Sebelum menjalankan aplikasi, jalankan perintah `flutter devices` untuk melihat daftar perangkat yang terhubung, lalu pilih target perangkat berdasarkan urutan prioritas berikut:
  1. **Prioritas 1 (Wi-Fi Debugging):** Cari perangkat Android/fisik yang terhubung melalui jaringan/Wi-Fi (biasanya memiliki ID berupa alamat IP seperti `192.168.x.x:5555` atau berakhiran `_adb-tls-connect._tcp`).
  2. **Prioritas 2 (USB Debugging):** Jika perangkat Wi-Fi tidak tersedia, pilih perangkat fisik Android/iOS yang terhubung melalui kabel USB.
  3. **Prioritas 3 (Linux Desktop):** Jika tidak ada perangkat fisik yang terhubung sama sekali, jalankan pada target desktop dengan ID `linux`.

- **Perintah Eksekusi:**
  - Untuk menjalankan dan menguji aplikasi secara umum, gunakan:
    `flutter run -d <DEVICE_ID_TERPILIH>`
  - Jika terdapat file integration test spesifik, jalankan di perangkat terpilih dengan perintah:
    `flutter run -d <DEVICE_ID_TERPILIH> integration_test/nama_file_test.dart`
  - Untuk target desktop Linux (jika masuk ke Prioritas 3), langsung gunakan:
    `flutter run -d linux`

- **Verifikasi Output:** Pantau log output di terminal `flutter run` hingga aplikasi selesai ter-build dan berjalan di layar, serta pastikan tidak ada _runtime error_ atau _exception_.
