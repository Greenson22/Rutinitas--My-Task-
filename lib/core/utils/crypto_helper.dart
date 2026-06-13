// lib/core/utils/crypto_helper.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';

class CryptoHelper {
  // Mengubah password pengguna menjadi kunci 32-byte (256-bit) menggunakan SHA-256
  static enc.Key _getKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Mengeksekusi enkripsi teks menggunakan AES-256 GCM
  static String encrypt(String plainText, String password) {
    try {
      final key = _getKey(password);
      final iv = enc.IV.fromSecureRandom(16); // Initialization Vector unik
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Simpan IV bersama data terenkripsi (dipisahkan oleh tanda titik dua)
      return "${iv.base64}:${encrypted.base64}";
    } catch (e) {
      throw Exception("Gagal mengenkripsi data: $e");
    }
  }

  /// Mengeksekusi dekripsi dari teks terenkripsi
  static String decrypt(String encryptedData, String password) {
    try {
      // Cek apakah data ini terenkripsi atau JSON biasa
      if (!encryptedData.contains(':')) {
        return encryptedData; // Kembalikan sebagai teks biasa (belum terenkripsi)
      }

      final parts = encryptedData.split(':');
      if (parts.length != 2) return encryptedData;

      final key = _getKey(password);
      final iv = enc.IV.fromBase64(parts[0]);
      final cipherText = enc.Encrypted.fromBase64(parts[1]);

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      return encrypter.decrypt(cipherText, iv: iv);
    } catch (e) {
      throw Exception("Kata sandi salah atau data korup.");
    }
  }
}
