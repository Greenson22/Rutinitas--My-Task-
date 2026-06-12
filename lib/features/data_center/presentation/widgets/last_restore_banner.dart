// lib/features/data_center/presentation/widgets/last_restore_banner.dart

import 'package:flutter/material.dart';

class LastRestoreBanner extends StatelessWidget {
  final Map<String, String>? lastRestoreInfo;

  const LastRestoreBanner({super.key, required this.lastRestoreInfo});

  @override
  Widget build(BuildContext context) {
    if (lastRestoreInfo == null) return const SizedBox.shrink();

    // Menentukan skema warna gradien dinamis berdasarkan string sumber data
    final bool isFromServer = lastRestoreInfo!['source']!
        .toLowerCase()
        .contains('server');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isFromServer
                ? [
                    const Color(0xFF0D324D),
                    const Color(0xFF7F5A83),
                  ] // Server Theme: Dark Blue Soft Purple
                : [
                    const Color(0xFF11998e),
                    const Color(0xFF38ef7d),
                  ], // Local Theme: Emerald Neon Green
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  (isFromServer
                          ? const Color(0xFF0D324D)
                          : const Color(0xFF11998e))
                      .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Efek watermark ikon transparan dekoratif di pojok kanan bawah
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  isFromServer ? Icons.dns_rounded : Icons.folder_zip_rounded,
                  size: 110,
                  color: Colors.white.withOpacity(0.09),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFromServer
                                    ? Icons.dns_outlined
                                    : Icons.inventory_2_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Sumber: ${lastRestoreInfo!['source']}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white60, width: 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "RESTORE AKTIF",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Terakhir Kali Di-restore:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastRestoreInfo!['time']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.file_present_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Berkas: ${lastRestoreInfo!['file']}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
