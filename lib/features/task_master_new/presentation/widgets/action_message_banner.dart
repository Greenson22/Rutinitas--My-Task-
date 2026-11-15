import 'package:flutter/material.dart';

/// Banner pesan aksi pengguna, dengan opsi coba lagi saat penyimpanan gagal.
class ActionMessageBanner extends StatelessWidget {
  const ActionMessageBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.brown[800],
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              key: const Key('retryActionButton'),
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          IconButton(
            tooltip: 'Tutup pesan',
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
