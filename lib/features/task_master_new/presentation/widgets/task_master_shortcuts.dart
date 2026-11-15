import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shortcut keyboard yang tersedia di Task Master New.
///
/// `Ctrl/Cmd + F` membuka pencarian, `Ctrl/Cmd + N` menambah item sesuai
/// konteks layar, dan `Esc` menjalankan aksi tutup yang diberikan. Dialog tetap
/// ditutup oleh rute dialog bawaan Flutter, sehingga [onEscape] hanya dipakai
/// ketika fokus berada di layar, bukan di dialog.
class TaskMasterShortcuts extends StatelessWidget {
  const TaskMasterShortcuts({
    super.key,
    required this.onSearch,
    required this.onAdd,
    this.onEscape,
    required this.child,
  });

  final VoidCallback onSearch;
  final VoidCallback onAdd;
  final VoidCallback? onEscape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): onSearch,
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): onSearch,
      const SingleActivator(LogicalKeyboardKey.keyN, control: true): onAdd,
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true): onAdd,
      if (onEscape != null)
        const SingleActivator(LogicalKeyboardKey.escape): onEscape!,
    };

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(autofocus: true, child: child),
    );
  }
}

/// Label tooltip yang menyebut shortcut agar pengguna desktop dapat
/// menemukannya tanpa membuka menu bantuan.
String shortcutTooltip(String label, {String? shortcut}) {
  if (shortcut == null || shortcut.isEmpty) return label;
  return '$label ($shortcut)';
}
