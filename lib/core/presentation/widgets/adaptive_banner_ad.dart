import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';

class AdaptiveBannerAd extends StatefulWidget {
  final String adKey;

  /// Menerima parameter [adKey] untuk menentukan iklan mana yang mau dipanggil dari MAP,
  /// misalnya 'task_master_banner' atau 'jurnal_banner'.
  const AdaptiveBannerAd({super.key, required this.adKey});

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  AdSize? _adaptiveAdSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pemuatan iklan dimasukkan di didChangeDependencies karena membutuhkan
    // context dari MediaQuery untuk menghitung lebar layar secara adaptif.
    if (_bannerAd == null) {
      _loadAdaptiveBanner();
    }
  }

  Future<void> _loadAdaptiveBanner() async {
    // 1. Dapatkan Ad Unit ID dari Map di AdService berdasarkan key yang dikirim
    final String adUnitId = AdService.getAdUnitId(widget.adKey);
    if (adUnitId.isEmpty) return;

    // 2. Hitung lebar layar perangkat saat ini dalam bentuk Density-Independent Pixels (dp)
    final int screenWidth = MediaQuery.sizeOf(context).width.truncate();

    // 3. Perbaikan Error: Menggunakan method standar orientasi saat ini untuk adaptive banner
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          screenWidth,
        );

    if (size == null) return;

    if (!mounted) return;

    setState(() {
      _adaptiveAdSize = size;
    });

    // 4. Inisialisasi dan muat objek BannerAd
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Iklan Adaptive Banner gagal dimuat: $err');
          ad.dispose(); // Hancurkan objek iklan untuk mencegah kebocoran memori[cite: 2]
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd
        ?.dispose(); // Mencegah kebocoran memori secara otomatis saat widget ditutup[cite: 2]
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan iklan hanya jika sudah berhasil dimuat dan ukuran adaptif telah siap
    if (_isAdLoaded && _bannerAd != null && _adaptiveAdSize != null) {
      return SafeArea(
        child: SizedBox(
          width: _adaptiveAdSize!.width.toDouble(),
          height: _adaptiveAdSize!.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    // Jika iklan belum termuat atau gagal, return widget kosong berukuran 0 agar UI tidak rusak[cite: 2]
    return const SizedBox.shrink();
  }
}
