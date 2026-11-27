// lib/features/about/presentation/pages/about_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  String _version = '...';
  late TabController _tabController;

  // State untuk manajemen rotasi ayat otomatis
  Timer? _verseTimer;
  int _currentVerseIndex = 0;

  // Daftar materi ayat Alkitab
  final List<Map<String, String>> _verses = [
    {
      'text':
          '"Serahkanlah perbuatanmu kepada TUHAN,\nmaka terlaksanalah segala rencanamu."',
      'ref': '— Amsal 16:3 —',
    },
    {
      'text':
          '"Bukan kepada kami, ya TUHAN, bukan kepada kami,\ntetapi kepada nama-Mulah beri kemuliaan,\noleh karena kasih-Mu, oleh karena setia-Mu!"',
      'ref': '— Mazmur 115:1 —',
    },
    {
      'text':
          '"Apapun juga yang kamu perbuat,\nperbuatlah dengan segenap hatimu\nseperti untuk Tuhan dan bukan untuk manusia."',
      'ref': '— Kolose 3:23 —',
    },
    {
      'text':
          '"Percayalah kepada TUHAN dengan segenap hatimu,\ndan janganlah bersandar kepada pengertianmu sendiri.\nAkuilah Dia dalam segala lakumu,\nmaka Ia akan meluruskan jalanmu."',
      'ref': '— Amsal 3:5-6 —',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPackageInfo();
    _initRandomVerse();
    _startVerseRotation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _verseTimer?.cancel(); // Mencegah memory leak akibat timer aktif
    super.dispose();
  }

  // Mengatur indeks awal ayat secara acak saat About dibuka
  void _initRandomVerse() {
    final random = Random();
    _currentVerseIndex = random.nextInt(_verses.length);
  }

  // Menjalankan rotasi perubahan ayat setiap 7 detik
  void _startVerseRotation() {
    _verseTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _currentVerseIndex = (_currentVerseIndex + 1) % _verses.length;
        });
      }
    });
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Versi ${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        backgroundColor:
            Colors.indigo[700], // Menyesuaikan dengan tema aplikasi[cite: 2]
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(text: 'Fitur Aplikasi'),
            Tab(text: 'Pengembang'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeaturesTab(context),
          _buildDeveloperTab(context, textTheme),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(BuildContext context) {
    // Informasi fitur yang telah diperluas dan dilengkapi sesuai pembaruan sistem aplikasi[cite: 2]
    final features = [
      {
        'icon': Icons.format_list_bulleted,
        'title': 'Task Master & Target Harian',
        'subtitle':
            'Kelola tugas berdasarkan kategori dengan target harian, pengurutan Hari Ini yang permanen, serta dukungan penambahan hitungan berkala.',
      },
      {
        'icon': Icons.stacked_line_chart,
        'title': 'Tipe Tugas Fleksibel',
        'subtitle':
            'Pilih tugas kebiasaan, penghitung, atau progres dengan Progress Bar dinamis sesuai kebutuhan rutinitas Anda.',
      },
      {
        'icon': Icons.checklist_rtl,
        'title': 'My Checklist Hubs',
        'subtitle':
            'Atur daftar rutinitas dalam multi-hub dengan sub-item bersarang, kontrol tampilan seksi, serta relasi antar item dan card.',
      },
      {
        'icon': Icons.attach_file,
        'title': 'Tautan Berkas Checklist',
        'subtitle':
            'Tautkan item checklist langsung ke berkas di My Documents dan buka berkasnya secara cepat dari menu item.',
      },
      {
        'icon': Icons.history_toggle_off,
        'title': 'DailyTracker & Riwayat',
        'subtitle':
            'Simpan progres harian pada card checklist dan pantau riwayat pencapaian Anda dari waktu ke waktu.',
      },
      {
        'icon': Icons.folder_copy_outlined,
        'title': 'My Documents (Folder Bertingkat)',
        'subtitle':
            'Kelompokkan berkas dalam group dan folder bersarang tanpa batas, lengkap dengan breadcrumb, ikon emoji, serta bagikan berkas atau folder ZIP.',
      },
      {
        'icon': Icons.note_alt_outlined,
        'title': 'My Notes',
        'subtitle':
            'Buat dan kelola catatan terstruktur dengan dukungan tampilan tabel dan pengaturan kolom yang fleksibel.',
      },
      {
        'icon': Icons.smart_button,
        'title': 'Manajemen Prompt',
        'subtitle':
            'Simpan dan organisir template teks atau prompt AI dengan rapi agar mudah dipakai ulang.',
      },
      {
        'icon': Icons.palette_outlined,
        'title': 'Kustomisasi Warna Adaptif',
        'subtitle':
            'Sesuaikan warna kartu menggunakan palet, color wheel, atau kode HEX dengan kontras teks otomatis.',
      },
      {
        'icon': Icons.menu_book,
        'title': 'Jurnal Aktivitas',
        'subtitle':
            'Catat durasi waktu produktif harian yang terhubung langsung dengan aktivitas Task Master.',
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'Statistik & Analitik',
        'subtitle':
            'Visualisasikan distribusi waktu produktif dan tren harian melalui grafik batang bertumpuk interaktif.',
      },
      {
        'icon': Icons.backup_outlined,
        'title': 'Data Center & Berbagi Lokal',
        'subtitle':
            'Ekspor, impor, backup ZIP seluruh data, serta sinkronisasi antar-perangkat dalam satu jaringan lokal.',
      },
      {
        'icon': Icons.folder_shared_outlined,
        'title': 'Penyimpanan Offline & Direktori Kustom',
        'subtitle':
            'Seluruh data tersimpan lokal di perangkat Anda dengan kebebasan memilih folder penyimpanan utama.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _AnimatedFeatureListItem(
          icon: feature['icon'] as IconData,
          title: feature['title'] as String,
          subtitle: feature['subtitle'] as String,
          index: index,
        );
      },
    );
  }

  Widget _buildDeveloperTab(BuildContext context, TextTheme textTheme) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final primaryColor = theme.primaryColor;
    final activeVerse = _verses[_currentVerseIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // ========================================================
          // CARD DEDIKASI DENGAN SISTEM ROTASI AYAT OTOMATIS & ACAK
          // ========================================================
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            color: primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 32 * textScaleFactor,
                    color: primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),

                  // AnimatedSwitcher untuk transisi fade-in fade-out saat ayat berganti
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      key: ValueKey<int>(
                        _currentVerseIndex,
                      ), // Memicu animasi rekonstruksi komponen
                      children: [
                        Text(
                          activeVerse['text']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14 * textScaleFactor,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeVerse['ref']!,
                          style: TextStyle(
                            fontSize: 12 * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Divider(
                      indent: 40,
                      endIndent: 40,
                      color: primaryColor.withOpacity(0.15),
                    ),
                  ),
                  Text(
                    'Puji dan syukur yang tak terhingga kepada TUHAN atas hikmat, kekuatan, dan tuntunan-Nya yang sempurna dari awal perancangan hingga terselesaikannya aplikasi ini. Segala kemuliaan hanya bagi nama-Nya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13 * textScaleFactor,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.85,
                      ),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // INFORMASI PENGEMBANG[cite: 2]
          // ========================================================
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  Colors.teal, // Menggunakan warna sekunder aplikasi[cite: 2]
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/pictures/profile.jpg'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Frendy Rikal Gerung, S.Kom.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Lulusan Sarjana Komputer dari Universitas Negeri Manado',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Dibuat dengan semangat untuk menyediakan alat bantu produktivitas yang personal. Menggabungkan manajemen tugas, rutinitas harian, catatan, pengelola prompt, dan pelacakan waktu (jurnal) yang berjalan secara offline untuk menjaga privasi data Anda.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.link, color: Colors.indigo),
                label: const Text(
                  'LinkedIn',
                  style: TextStyle(color: Colors.indigo),
                ),
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://linkedin.com/in/frendy-rikal-gerung-bb450b38a/',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(Icons.email_outlined, color: Colors.indigo),
                label: const Text(
                  'Email',
                  style: TextStyle(color: Colors.indigo),
                ),
                onPressed: () =>
                    launchUrl(Uri.parse('mailto:frendyrikalgerung@gmail.com')),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(_version, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AnimatedFeatureListItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;

  const _AnimatedFeatureListItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AnimatedFeatureListItem> createState() =>
      __AnimatedFeatureListItemState();
}

class __AnimatedFeatureListItemState extends State<_AnimatedFeatureListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: Colors
                      .indigo[700], // Menyesuaikan tema warna aplikasi[cite: 2]
                  size: 32,
                ),
              ],
            ),
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
