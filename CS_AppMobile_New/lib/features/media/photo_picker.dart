import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Helper per acquisire una foto da camera o galleria.
/// Rimpiazza `cordova-plugin-camera` (openCamera) dell'app originale.
class PhotoPicker {
  PhotoPicker._();

  static final ImagePicker _picker = ImagePicker();

  /// Mostra la scelta Camera/Galleria e ritorna i byte JPEG, o null.
  static Future<Uint8List?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Scatta foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Scegli da galleria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return pickFrom(source);
  }

  /// Acquisisce direttamente da una sorgente specifica.
  static Future<Uint8List?> pickFrom(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
