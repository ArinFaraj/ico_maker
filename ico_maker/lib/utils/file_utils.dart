import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileUtils {
  // Open a file picker dialog and return the selected file as bytes
  static Future<Uint8List?> openFile({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.bytes;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  // Save a file using a file picker dialog
  static Future<bool> saveFile(
    Uint8List bytes, {
    String? fileName,
    String? dialogTitle,
    List<String>? allowedExtensions,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Save file',
        fileName: fileName,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      if (path != null) {
        // Use the platform file saver to save the bytes to the path
        File(path).writeAsBytesSync(bytes);
        return true;
      }
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
    return false;
  }
}
