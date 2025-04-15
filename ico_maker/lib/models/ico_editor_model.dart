import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ico_dart/ico_dart.dart';
import 'package:image/image.dart' as img;

import '../utils/image_utils.dart';

// Extension to add creation methods to IcoFile
extension IcoFileExtension on IcoFile {
  static IcoFile empty() {
    // Create an empty ICO file with no entries
    final header = IcoHeader(
      reserved: 0,
      imageType: 1, // 1 for icon
      imageCount: 0,
    );
    return IcoFile.fromBytes(header.toBytes());
  }
}

class IcoEditorModel extends ChangeNotifier {
  IcoFile? _icoFile;
  int _selectedEntryIndex = -1;
  bool _isDirty = false;

  IcoFile? get icoFile => _icoFile;
  bool get hasIcoFile => _icoFile != null;
  bool get isDirty => _isDirty;

  List<IconDirectoryEntry> get entries => _icoFile?.directoryEntries ?? [];

  int get selectedEntryIndex => _selectedEntryIndex;
  IconDirectoryEntry? get selectedEntry =>
      (_selectedEntryIndex >= 0 && _selectedEntryIndex < entries.length)
          ? entries[_selectedEntryIndex]
          : null;

  void createNew() {
    _icoFile = IcoFileExtension.empty();
    _selectedEntryIndex = -1;
    _isDirty = true;
    notifyListeners();
  }

  void loadFromBytes(Uint8List bytes) {
    try {
      // Load the ICO file from bytes
      _icoFile = IcoFile.fromBytes(bytes);

      // Normalize the entries to ensure they're consistent
      if (_icoFile != null && _icoFile!.directoryEntries.isNotEmpty) {
        final normalizedEntries = <IconDirectoryEntry>[];

        for (final entry in _icoFile!.directoryEntries) {
          // Try to decode the image data to make sure it's valid
          final image = ImageUtils.bytesToImage(entry.imageData);

          if (image != null) {
            // Re-encode it to ensure it's properly formatted
            final processedImage = _ensureAlphaChannel(image);
            final processedBytes = img.encodePng(processedImage);

            // Create a normalized entry with proper values
            final normalizedEntry = IconDirectoryEntry(
              width: entry.width,
              height: entry.height,
              colorCount: entry.colorCount,
              reserved: entry.reserved,
              numPlanes: entry.numPlanes,
              bitsPerPixel: entry.bitsPerPixel,
              imageSize: processedBytes.length,
              imageOffset:
                  entry.imageOffset, // Will be recalculated when saving
              imageData: processedBytes,
            );

            normalizedEntries.add(normalizedEntry);
          } else {
            // If image can't be decoded, just use the original entry
            normalizedEntries.add(entry);
          }
        }

        // Clear existing entries and add the normalized ones
        _icoFile!.directoryEntries.clear();
        _icoFile!.directoryEntries.addAll(normalizedEntries);
      }

      _selectedEntryIndex = _icoFile!.directoryEntries.isNotEmpty ? 0 : -1;
      _isDirty = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading ICO file: $e');
      // Create a new empty file if loading fails
      createNew();
    }
  }

  Uint8List? saveToBytes() {
    if (_icoFile == null) return null;

    try {
      // 1. Create the ICO header
      final int entryCount = _icoFile!.directoryEntries.length;
      final header = IcoHeader(
        reserved: 0, // Always 0
        imageType: 1, // 1 for icon, 2 for cursor
        imageCount: entryCount,
      );

      // 2. Calculate header and directory size to determine starting offset for image data
      final int headerSize = IcoHeader.headerSize; // 6 bytes
      final int directorySize =
          IconDirectoryEntry.entrySize * entryCount; // 16 bytes per entry
      int currentOffset = headerSize + directorySize;

      // 3. Create updated entries with correct offsets
      final updatedEntries = <IconDirectoryEntry>[];

      for (final entry in _icoFile!.directoryEntries) {
        final updatedEntry = IconDirectoryEntry(
          width: entry.width,
          height: entry.height,
          colorCount: entry.colorCount,
          reserved: entry.reserved,
          numPlanes: entry.numPlanes,
          bitsPerPixel: entry.bitsPerPixel,
          imageSize: entry.imageData.length,
          imageOffset: currentOffset, // Set the correct offset
          imageData: entry.imageData,
        );

        updatedEntries.add(updatedEntry);
        currentOffset += entry.imageData.length;
      }

      // 4. Write the ICO file bytes manually
      // 4.1 Write header
      final headerBytes = header.toBytes();

      // 4.2 Write directory entries
      final directoryBytes = <int>[];
      for (final entry in updatedEntries) {
        directoryBytes.addAll(entry.toBytes());
      }

      // 4.3 Write image data
      final imageBytes = <int>[];
      for (final entry in updatedEntries) {
        imageBytes.addAll(entry.imageData);
      }

      // 5. Combine all bytes
      final allBytes = <int>[];
      allBytes.addAll(headerBytes);
      allBytes.addAll(directoryBytes);
      allBytes.addAll(imageBytes);

      _isDirty = false;
      notifyListeners();

      return Uint8List.fromList(allBytes);
    } catch (e) {
      debugPrint('Error saving ICO file: $e');
      return null;
    }
  }

  void selectEntry(int index) {
    if (index >= -1 && index < entries.length) {
      _selectedEntryIndex = index;
      notifyListeners();
    }
  }

  void addEntry(IconDirectoryEntry entry) {
    if (_icoFile == null) return;

    // We need to create a new ICO file with the updated entries
    final updatedEntries = List<IconDirectoryEntry>.from(
      _icoFile!.directoryEntries,
    )..add(entry);

    // Load the current file as bytes and modify it
    final currentBytes = _icoFile!.toBytes();
    _icoFile = IcoFile.fromBytes(currentBytes);

    // Replace the directory entries with our updated list
    // This is a hack since we can't directly modify the private field
    _icoFile!.directoryEntries.clear();
    _icoFile!.directoryEntries.addAll(updatedEntries);

    _selectedEntryIndex = _icoFile!.directoryEntries.length - 1;
    _isDirty = true;
    notifyListeners();
  }

  void updateEntryImage(int index, Uint8List imageData) {
    if (_icoFile == null || index < 0 || index >= entries.length) return;

    final entry = entries[index];
    final newEntry = IconDirectoryEntry(
      width: entry.width,
      height: entry.height,
      colorCount: entry.colorCount,
      reserved: entry.reserved,
      numPlanes: entry.numPlanes,
      bitsPerPixel: entry.bitsPerPixel,
      imageSize: imageData.length,
      imageOffset: entry.imageOffset,
      imageData: imageData,
    );

    // Create a new list with the updated entry
    final updatedEntries = List<IconDirectoryEntry>.from(
      _icoFile!.directoryEntries,
    );
    updatedEntries[index] = newEntry;

    // Load the current file as bytes and modify it
    final currentBytes = _icoFile!.toBytes();
    _icoFile = IcoFile.fromBytes(currentBytes);

    // Replace the directory entries with our updated list
    _icoFile!.directoryEntries.clear();
    _icoFile!.directoryEntries.addAll(updatedEntries);

    _isDirty = true;
    notifyListeners();
  }

  void removeEntry(int index) {
    if (_icoFile == null || index < 0 || index >= entries.length) return;

    // Create a new list without the removed entry
    final updatedEntries = List<IconDirectoryEntry>.from(
      _icoFile!.directoryEntries,
    );
    updatedEntries.removeAt(index);

    // Load the current file as bytes and modify it
    final currentBytes = _icoFile!.toBytes();
    _icoFile = IcoFile.fromBytes(currentBytes);

    // Replace the directory entries with our updated list
    _icoFile!.directoryEntries.clear();
    _icoFile!.directoryEntries.addAll(updatedEntries);

    if (_selectedEntryIndex >= entries.length) {
      _selectedEntryIndex = entries.isEmpty ? -1 : entries.length - 1;
    }

    _isDirty = true;
    notifyListeners();
  }

  // Create a new entry from an image
  IconDirectoryEntry createEntryFromImage(img.Image image) {
    // Validate that width and height are within valid range
    final width = image.width <= 255 ? image.width : 0; // 0 means 256
    final height = image.height <= 255 ? image.height : 0; // 0 means 256

    // Make sure alpha channel is properly set for all pixels
    img.Image processedImage = _ensureAlphaChannel(image);
    final processedBytes = img.encodePng(processedImage);

    return IconDirectoryEntry(
      width: width,
      height: height,
      colorCount: 0, // 0 means 256 or more colors
      reserved: 0,
      numPlanes: 1,
      bitsPerPixel: 32,
      imageSize: processedBytes.length,
      imageOffset: 0, // Will be calculated when saving
      imageData: processedBytes,
    );
  }

  // Ensure image has proper alpha channel
  img.Image _ensureAlphaChannel(img.Image image) {
    final result = img.Image.from(image);

    // Make sure transparent pixels are completely transparent
    // And opaque pixels have full alpha
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        // If pixel has low alpha, make it fully transparent
        if (pixel.a < 128) {
          result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        } else if (pixel.a < 255) {
          // Otherwise ensure full alpha
          result.setPixel(
            x,
            y,
            img.ColorRgba8(
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              255,
            ),
          );
        }
      }
    }

    return result;
  }
}
