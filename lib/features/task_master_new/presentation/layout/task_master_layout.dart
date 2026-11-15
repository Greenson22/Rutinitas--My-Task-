/// Batas lebar untuk pola layout Task Master New.
///
/// Mobile memakai satu panel dengan push ke halaman detail, tablet memakai
/// satu panel yang lebih lebar, dan desktop memakai dua panel.
const double taskMasterTabletBreakpoint = 600;
const double taskMasterDesktopBreakpoint = 1024;

/// Lebar maksimum isi pada layout satu panel agar baris teks tetap nyaman
/// dibaca di tablet dan desktop yang sempit.
const double taskMasterSinglePaneMaxWidth = 760;

/// Pola layout yang dipakai Task Master New pada lebar tertentu.
enum TaskMasterLayout { mobile, tablet, desktop }

/// Menentukan pola layout dari lebar layar logis.
///
/// Batas bersifat inklusif di sisi bawah: `600` termasuk tablet dan `1024`
/// termasuk tablet, sedangkan di atas `1024` baru menjadi desktop.
TaskMasterLayout taskMasterLayoutForWidth(double width) {
  if (width < taskMasterTabletBreakpoint) return TaskMasterLayout.mobile;
  if (width <= taskMasterDesktopBreakpoint) return TaskMasterLayout.tablet;
  return TaskMasterLayout.desktop;
}

/// Apakah layout memakai dua panel (daftar kategori + detail).
bool usesTwoPaneLayout(TaskMasterLayout layout) =>
    layout == TaskMasterLayout.desktop;

/// Apakah navigasi kategori memakai push halaman, bukan panel kanan.
bool usesPushedCategoryDetail(TaskMasterLayout layout) =>
    layout == TaskMasterLayout.mobile || layout == TaskMasterLayout.tablet;
