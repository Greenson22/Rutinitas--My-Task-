// lib/features/task_master/presentation/widgets/task_master_empty_state.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class TaskMasterEmptyState extends StatefulWidget {
  final VoidCallback onAddCategoryPressed;

  const TaskMasterEmptyState({super.key, required this.onAddCategoryPressed});

  @override
  State<TaskMasterEmptyState> createState() => _TaskMasterEmptyStateState();
}

class _TaskMasterEmptyStateState extends State<TaskMasterEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Controller untuk memutar kilauan latar belakang secara infinit (looping)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
            // ================= VISUAL HERO ANIMASI =================
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Efek Flare/Pancaran Berputar di Latar Belakang
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
                      painter: FlareBackgroundPainter(),
                    ),
                  ),
                  // 2. Lingkaran Glow Halus Tengah
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // 3. Ikon Utama dengan Animasi Mengambang (Floating Effect)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
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
                            Icons.assignment_turned_in_rounded,
                            size: 76,
                            color: Colors.indigo[600],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ================= KONTEN TEKS & INFORMASI =================
            // Efek Fade-In untuk Judul Utama
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
                'Mulai Langkah Produktif Anda!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Efek Fade-In Berurutan untuk Deskripsi Kegunaan
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
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.withOpacity(0.05)),
                ),
                child: Text(
                  'Task Master membantu Anda melacak repetisi aktivitas, target progress bar, dan terhubung langsung dengan Jurnal Waktu 30 menit Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ================= TOMBOL AKSI UTAMA =================
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: ElevatedButton.icon(
                onPressed: widget.onAddCategoryPressed,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
                label: const Text(
                  'Buat Kategori Pertama',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: Colors.indigo.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar pancaran kelopak estetik (Flare Background) di belakang ikon
class FlareBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;
    const int rayCount = 8;

    for (int i = 0; i < rayCount; i++) {
      final double angle = (i * 2 * math.pi) / rayCount;
      final path = Path();

      // Menggambar bentuk pancaran kelopak dinamis yang mengecil ke ujung luar
      path.moveTo(center.dx, center.dy);
      path.quadraticBezierTo(
        center.dx + math.cos(angle - 0.2) * (maxRadius * 0.5),
        center.dy + math.sin(angle - 0.2) * (maxRadius * 0.5),
        center.dx + math.cos(angle) * maxRadius,
        center.dy + math.sin(angle) * maxRadius,
      );
      path.quadraticBezierTo(
        center.dx + math.cos(angle + 0.2) * (maxRadius * 0.5),
        center.dy + math.sin(angle + 0.2) * (maxRadius * 0.5),
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
