class StringHelper {
  /// Memformat angka integer menjadi format ribuan dengan pembatas titik (.)
  /// Contoh: 1000000 -> 1.000.000
  static String formatRibuan(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  // Anda bisa menyimpan helper text/string umum lainnya di sini nanti, contoh:
  // static String capitalize(String text) => ...
}
