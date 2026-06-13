// lib/features/jurnal_aktivitas/presentation/widgets/jurnal_empty_state.dart
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';

class JurnalEmptyState extends StatelessWidget {
  final VoidCallback onPressed;

  const JurnalEmptyState({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return UniversalEmptyState(
      icon: Icons.edit_calendar_rounded,
      title: 'Jurnal Hari Ini Masih Kosong',
      description:
          'Kamu belum mencatat produktivitas atau kegiatan apa pun hari ini. Yuk, mulai rekam aktivitas pertamamu sekarang juga!',
      buttonLabel: 'Catat Aktivitas Sekarang',
      themeColor: Colors.indigo,
      onPressed: onPressed,
    );
  }
}
