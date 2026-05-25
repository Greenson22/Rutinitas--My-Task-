// lib/features/about/presentation/pages/about_page.dart

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPackageInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Colors.indigo[700], // Menyesuaikan dengan tema aplikasi
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
    // Disesuaikan dengan fitur aplikasi Task Master, Daily, dan Jurnal Aktivitas
    final features = [
      {
        'icon': Icons.format_list_bulleted,
        'title': 'Task Master',
        'subtitle':
            'Kelola tugas Anda berdasarkan kategori dengan target hitungan harian.',
      },
      {
        'icon': Icons.wb_sunny_outlined,
        'title': 'Daily Checklist',
        'subtitle':
            'Atur prioritas rutinitas ke dalam Fokus Utama, Rutinitas Inti, dan Pelengkap.',
      },
      {
        'icon': Icons.menu_book,
        'title': 'Jurnal Aktivitas',
        'subtitle':
            'Lacak waktu produktif Anda dan hubungkan durasi dengan tugas yang ada.',
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'Statistik & Analitik',
        'subtitle':
            'Visualisasikan distribusi waktu dan tren harian melalui grafik interaktif.',
      },
      {
        'icon': Icons.folder_shared_outlined,
        'title': 'Penyimpanan Offline',
        'subtitle':
            'Data disimpan sepenuhnya secara lokal (JSON) untuk menjamin privasi Anda.',
      },
      {
        'icon': Icons.tune,
        'title': 'Kustomisasi Fleksibel',
        'subtitle':
            'Ubah warna, ikon kategori, dan letak folder penyimpanan sesuai keinginan.',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Colors.teal, // Menggunakan warna sekunder aplikasi
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
            'Dibuat dengan semangat untuk menyediakan alat bantu produktivitas yang personal. Menggabungkan manajemen tugas, rutinitas harian, dan pelacakan waktu (jurnal) yang berjalan secara offline untuk menjaga privasi data Anda.',
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
                    launchUrl(Uri.parse('mailto:frendydev1@gmail.com')),
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
                  color: Colors.indigo[700], // Menyesuaikan tema warna aplikasi
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
