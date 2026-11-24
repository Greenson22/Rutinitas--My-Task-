import 'package:flutter/material.dart';

/// Menghasilkan warna deterministik dari [name] menggunakan djb2 hash → HSL.
/// Saturation = 0.6 dan lightness = 0.55 tetap untuk semua item.
Color colorFromItemName(String name) {
  int hash = 5381;
  for (final c in name.codeUnits) {
    hash = ((hash << 5) + hash) + c;
    hash &= 0xFFFFFFFF;
  }
  final double hue = (hash % 360).toDouble().abs();
  return HSLColor.fromAHSL(1.0, hue, 0.6, 0.55).toColor();
}
