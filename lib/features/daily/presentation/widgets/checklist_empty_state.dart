// lib/features/daily/presentation/widgets/checklist_empty_state.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ChecklistEmptyState extends StatefulWidget {
  final VoidCallback onAddItemPressed;

  const ChecklistEmptyState({super.key, required this.onAddItemPressed});

  @override
  State<ChecklistEmptyState> createState() => _ChecklistEmptyStateState();
}

class _ChecklistEmptyStateState extends State<ChecklistEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Efek putar infinit untuk aksen flare dekorasi di belakang ikon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ================= ANIMASI HERO VISUAL =================
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Pancaran Kelopak Berputar Perlahan (Tema Teal)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: ChecklistFlarePainter(),
                    ),
                  ),
                  // 2. Lingkaran Dasar Putih dengan Glow Bayangan Lembut
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // 3. Ikon Checklist Utama Dengan Animasi Melayang Sinusoidal
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOutBack,
                    builder: (context, scaleValue, child) {
                      return Transform.scale(
                        scale: scaleValue,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 6),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOutSine,
                          builder: (context, floatValue, child) {
                            return Transform.translate(
                              offset: Offset(0, -floatValue),
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.fact_check_rounded,
                            size: 72,
                            color: Colors.teal[600],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ================= SEKSI TEKS & DESKRIPSI =================
            // Efek Muncul Lembut (Fade-In) untuk Judul Utama
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                'Materi Checklist Masih Kosong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[900],
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Efek Pudar Berurutan untuk Deskripsi Kotak Transparan
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.withOpacity(0.08)),
                ),
                child: Text(
                  'Kelompok grup checklist ini belum memiliki daftar tugas atau materi harian. Tekan tombol di bawah untuk membuat rutinitas pertama Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey[800],
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ================= TOMBOL AKSI UTAMA MANTAP =================
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: ElevatedButton.icon(
                onPressed: widget.onAddItemPressed,
                icon: const Icon(
                  Icons.add_box_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                label: const Text(
                  'Tambah Item Pertama',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                  shadowColor: Colors.teal.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menggambar pancaran seni abstrak hiasan bertema Teal transparan di balik ikon
class ChecklistFlarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;
    const int rayCount = 8;

    for (int i = 0; i < rayCount; i++) {
      final double angle = (i * 2 * math.pi) / rayCount;
      final path = Path();

      path.moveTo(center.dx, center.dy);
      path.quadraticBezierTo(
        center.dx + math.cos(angle - 0.25) * (maxRadius * 0.5),
        center.dy + math.sin(angle - 0.25) * (maxRadius * 0.5),
        center.dx + math.cos(angle) * maxRadius,
        center.dy + math.sin(angle) * maxRadius,
      );
      path.quadraticBezierTo(
        center.dx + math.cos(angle + 0.25) * (maxRadius * 0.5),
        center.dy + math.sin(angle + 0.25) * (maxRadius * 0.5),
        center.dx,
        center.dy,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
