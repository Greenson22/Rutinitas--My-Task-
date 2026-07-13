// lib/features/data_center/presentation/widgets/transfer_progress_dialog.dart
import 'package:flutter/material.dart';

class TransferProgressDialog extends StatelessWidget {
  final String title;
  final ValueNotifier<String> statusNotifier;
  final bool isSending;
  final String subTitleProgress;
  final VoidCallback onClose;

  const TransferProgressDialog({
    super.key,
    required this.title,
    required this.statusNotifier,
    required this.isSending,
    required this.subTitleProgress,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isSending ? Colors.teal : Colors.indigo;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol Keluar (X) yang dinonaktifkan/diaktifkan
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: onClose,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      backgroundColor: accentColor.withOpacity(0.1),
                    ),
                  ),
                  Icon(
                    isSending
                        ? Icons.swap_vertical_circle_outlined
                        : Icons.cloud_download_rounded,
                    size: 40,
                    color: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String>(
              valueListenable: statusNotifier,
              builder: (context, status, child) {
                return Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    subTitleProgress.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
