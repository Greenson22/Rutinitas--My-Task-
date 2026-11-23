# 04: UI Card — Toggle Aktivasi & Badge DailyTracker

**What to build:** Pengguna dapat mengaktifkan atau menonaktifkan mode DailyTracker pada sebuah card `DailySubject` melalui popup menu card yang sudah ada di `ChecklistDetailScreen`. Ketika DailyTracker aktif, card menampilkan badge visual kecil (ikon kalender atau label "Daily") di area header card. Ketika nonaktif, card tampil identik dengan kondisi sebelum fitur ini ada — zero visual noise. Perubahan status disimpan langsung ke file JSON melalui `saveGroupData()`.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Popup menu card di `ChecklistDetailScreen` memiliki item baru: "Aktifkan DailyTracker" (jika `isDailyTrackerEnabled == false`) atau "Nonaktifkan DailyTracker" (jika `isDailyTrackerEnabled == true`).
- [ ] Menekan item menu tersebut membalik nilai `isDailyTrackerEnabled` dan memanggil `saveGroupData()`.
- [ ] Card dengan `isDailyTrackerEnabled == true` menampilkan badge penanda DailyTracker yang terlihat jelas di area header.
- [ ] Card dengan `isDailyTrackerEnabled == false` tidak menampilkan badge atau elemen tambahan apapun.
- [ ] Widget test: badge muncul di tree widget ketika `isDailyTrackerEnabled == true`.
- [ ] Widget test: badge tidak ada di tree widget ketika `isDailyTrackerEnabled == false`.
- [ ] Widget test: item menu "Aktifkan DailyTracker" muncul pada card yang nonaktif, dan sebaliknya.
