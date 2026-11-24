import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/utils/item_color_helper.dart';

void main() {
  group('colorFromItemName', () {
    test('nama yang sama dipanggil berulang kali menghasilkan Color yang identik', () {
      final c1 = colorFromItemName('Sholat Subuh');
      final c2 = colorFromItemName('Sholat Subuh');
      final c3 = colorFromItemName('Sholat Subuh');

      expect(c1, equals(c2));
      expect(c2, equals(c3));
    });

    test('dua nama berbeda menghasilkan warna berbeda', () {
      final c1 = colorFromItemName('Sholat Subuh');
      final c2 = colorFromItemName('Olahraga Pagi');

      expect(c1, isNot(equals(c2)));
    });

    test('nama kosong tidak throw exception dan menghasilkan Color valid', () {
      final color = colorFromItemName('');
      final hsl = HSLColor.fromColor(color);

      expect(color, isA<Color>());
      expect(hsl.hue, greaterThanOrEqualTo(0.0));
      expect(hsl.hue, lessThan(360.0));
    });

    test('nama berisi karakter Unicode dan emoji tidak throw exception', () {
      final color = colorFromItemName('🎯 Baca Quran 📖 — Juz 1');
      final hsl = HSLColor.fromColor(color);

      expect(color, isA<Color>());
      expect(hsl.hue, greaterThanOrEqualTo(0.0));
      expect(hsl.hue, lessThan(360.0));
    });
  });
}
