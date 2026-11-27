// lib/core/presentation/widgets/ad_notice_dialog.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog informasi iklan yang muncul sekali setiap kali aplikasi baru dibuka.
/// State sesi direset otomatis ketika aplikasi ditutup dan dibuka kembali.
class AdNoticeDialog extends StatefulWidget {
  const AdNoticeDialog({super.key});

  static const String prefKey = 'show_ad_notice_on_startup';
  static bool _hasShownThisSession = false;

  /// Menampilkan dialog jika opsi di Pengaturan aktif dan belum pernah
  /// ditampilkan pada sesi aplikasi saat ini.
  static Future<void> showIfEnabled(BuildContext context) async {
    if (_hasShownThisSession) return;
    _hasShownThisSession = true;

    final prefs = await SharedPreferences.getInstance();
    final shouldShow = prefs.getBool(prefKey) ?? true;
    if (!shouldShow || !context.mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup info iklan',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AdNoticeDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AdNoticeDialog> createState() => _AdNoticeDialogState();
}

class _AdNoticeDialogState extends State<AdNoticeDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 12,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade400,
                        Colors.deepPurple.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terima Kasih Telah Hadir',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aplikasi ini menghadirkan iklan yang tidak dapat dimatikan. '
                'Setiap iklan yang tampil adalah penopang nyata bagi developer '
                'untuk terus berkarya, merawat, dan menghadirkan fitur-fitur '
                'terbaik bagi Anda secara gratis.\n\n'
                'Dengan segala kerendahan hati, kami memohon pengertian dan '
                'kelapangan hati Anda untuk menerima kehadiran iklan ini '
                'sebagai bentuk dukungan tulus agar aplikasi ini dapat terus '
                'bertahan dan menemani rutinitas Anda setiap hari.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.2,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Colors.indigo.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ingin menonaktifkan pesan ini saat aplikasi dibuka? '
                        'Buka menu Pengaturan (ikon gerigi di laci menu) lalu '
                        'matikan opsi "Tampilkan Info Iklan Saat Buka Aplikasi".',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                  label: const Text(
                    'Saya Mengerti & Dukung',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
