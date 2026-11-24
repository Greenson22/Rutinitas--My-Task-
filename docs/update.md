# Update 2.3.2

## ✅ Fitur Baru

### Checklist — Kaitan Akumulasi Lintas Card
- Setiap item checklist kini memiliki ID unik, menggantikan identifikasi berbasis nama yang bisa tabrakan
- Kaitan akumulasi lintas card sekarang menggunakan ID unik, sehingga dua item bernama sama di card berbeda tidak tertukar
- Data lama (kaitan berbasis nama) tetap berfungsi secara otomatis melalui mekanisme fallback

### Checklist — Tampilan Jumlah Akumulasi di Tree View
- Item kecil yang terkait ke item besar di card lain kini menampilkan angka akumulasi terkini di sebelah ikon ⚡
- Format tampilan: `⚡ (nilaiSekarang/nilaiTarget)`, contoh: `⚡ (45/100)`
- Angka akumulasi otomatis diperbarui saat nilai item target berubah
- Tampilan muncul baik di mode normal maupun mode edit pada dialog checklist

---

## 🔧 Perbaikan

### Checklist — Sinkronisasi Persentase History dan Card
- Persentase bar chart di halaman History kini identik dengan persentase progress bar di card checklist
- Kalkulasi persentase dipusatkan ke satu fungsi (`ChecklistCalculationHelper`) sebagai sumber kebenaran tunggal
- Item bertipe progress dan countdown dihitung secara proporsional di history (sama seperti di card)
- Sebelumnya: history menggunakan perhitungan sederhana berbasis jumlah item (integer), card menggunakan perhitungan proporsional (desimal)

### Checklist — Item Dinonaktifkan Dikecualikan dari Persentase
- Item yang dinonaktifkan tidak lagi masuk dalam perhitungan persentase di seluruh aplikasi
- Berlaku di: card checklist, dialog controller, dan bar chart history
- Snapshot harian (history) menyimpan status nonaktif item saat data disimpan, sehingga history tetap akurat

### Checklist — Stabilitas Data & Backward Compatibility
- JSON data lama yang belum memiliki field `id` pada item akan mendapat ID otomatis saat dibuka, tanpa kehilangan data
- JSON data lama yang belum memiliki field `isDisabled` pada log harian dibaca dengan nilai default `false` secara otomatis
