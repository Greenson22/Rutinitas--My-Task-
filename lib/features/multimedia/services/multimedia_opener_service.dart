import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/dialogs/multimedia_audio_dialog.dart';
import '../presentation/dialogs/multimedia_image_dialog.dart';

/// Layanan untuk membuka berkas multimedia (gambar/audio) secara internal
/// melalui dialog atau secara eksternal sesuai pengaturan pengguna.
class MultimediaOpenerService {
  static const String prefOpenImageInternal = 'multimedia_open_image_internal';
  static const String prefOpenAudioInternal = 'multimedia_open_audio_internal';

  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
  };

  static const Set<String> _audioExtensions = {
    '.mp3',
    '.wav',
    '.m4a',
    '.aac',
    '.ogg',
    '.flac',
    '.opus',
  };

  static Future<void> openFile(BuildContext context, File file) async {
    final lowerPath = file.path.toLowerCase();
    final isImage = _imageExtensions.any(lowerPath.endsWith);
    final isAudio = _audioExtensions.any(lowerPath.endsWith);

    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;

    if (isImage) {
      final useInternal = prefs.getBool(prefOpenImageInternal) ?? true;
      if (useInternal) {
        await MultimediaImageDialog.show(context, file);
        return;
      }
    } else if (isAudio) {
      final useInternal = prefs.getBool(prefOpenAudioInternal) ?? true;
      if (useInternal) {
        await MultimediaAudioDialog.show(context, file);
        return;
      }
    }

    await OpenFile.open(file.path);
  }
}
