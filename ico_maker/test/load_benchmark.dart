import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ico_maker/models/ico_editor_model.dart';
import 'package:ico_dart/ico_dart.dart';
import 'package:image/image.dart' as img;

void main() {
  test('Benchmark loadFromBytes', () {
    // 1. Create a large dummy ICO file
    // We create a simple image
    final image = img.Image(width: 256, height: 256);
    // Fill with some data
    for(int y=0; y<256; y++) {
      for(int x=0; x<256; x++) {
        image.setPixel(x, y, img.ColorRgba8(x % 255, y % 255, (x+y) % 255, 128)); // Semi-transparent
      }
    }

    final pngBytes = img.encodePng(image);

    // Create an entry
    final entry = IconDirectoryEntry(
      width: 0, // 256
      height: 0, // 256
      colorCount: 0,
      reserved: 0,
      numPlanes: 1,
      bitsPerPixel: 32,
      imageSize: pngBytes.length,
      imageOffset: 22, // Header (6) + 1 entry (16)
      imageData: Uint8List.fromList(pngBytes),
    );

    // Create header
    final header = IcoHeader(
      reserved: 0,
      imageType: 1,
      imageCount: 1,
    );

    // Combine
    final bytes = Uint8List.fromList([
      ...header.toBytes(),
      ...entry.toBytes(),
      ...entry.imageData,
    ]);

    final model = IcoEditorModel();

    final stopwatch = Stopwatch()..start();
    // Run multiple times to get a better measurement
    for (int i = 0; i < 10; i++) {
        model.loadFromBytes(bytes);
    }
    stopwatch.stop();

    print('Time taken for 10 loads: ${stopwatch.elapsedMilliseconds}ms');
    print('Average time per load: ${stopwatch.elapsedMilliseconds / 10}ms');
  });
}
