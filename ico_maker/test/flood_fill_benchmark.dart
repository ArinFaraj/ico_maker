import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// Helper to mock getPixelColor from ImageUtils
Color? getPixelColor(img.Image image, int x, int y) {
  if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
    return null;
  }

  final pixel = image.getPixel(x, y);
  return Color.fromARGB(
    pixel.a.toInt(),
    pixel.r.toInt(),
    pixel.g.toInt(),
    pixel.b.toInt(),
  );
}

void main() {
  test('Flood Fill Benchmark', () {
    print('Starting Benchmark...');

    // Setup
    final int width = 500;
    final int height = 500;
    final img.Image baseImage = img.Image(width: width, height: height, numChannels: 4);
    // Fill with white
    img.fill(baseImage, color: img.ColorRgba8(255, 255, 255, 255));

    // Draw a black border to contain the fill
    // Top and Bottom
    for(int x=0; x<width; x++) {
        baseImage.setPixel(x, 0, img.ColorRgba8(0, 0, 0, 255));
        baseImage.setPixel(x, height-1, img.ColorRgba8(0, 0, 0, 255));
    }
    // Left and Right
    for(int y=0; y<height; y++) {
        baseImage.setPixel(0, y, img.ColorRgba8(0, 0, 0, 255));
        baseImage.setPixel(width-1, y, img.ColorRgba8(0, 0, 0, 255));
    }

    final targetColor = Colors.red;

    // Benchmark Original (Inefficient)
    final stopwatch1 = Stopwatch()..start();
    fillOriginal(img.Image.from(baseImage), width ~/ 2, height ~/ 2, targetColor);
    stopwatch1.stop();
    print('Original Implementation Time: ${stopwatch1.elapsedMilliseconds} ms');

    // Benchmark Optimized (Queue BFS)
    final stopwatch2 = Stopwatch()..start();
    fillOptimized(img.Image.from(baseImage), width ~/ 2, height ~/ 2, targetColor);
    stopwatch2.stop();
    print('Optimized Implementation Time: ${stopwatch2.elapsedMilliseconds} ms');

    expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));
  });
}

void fillOriginal(img.Image image, int x, int y, Color targetColor) {
    final sourceColor = getPixelColor(image, x, y);
    if (sourceColor == null) return;
    if (sourceColor.value == targetColor.value) return;

    final visited = <String>{};
    final queue = <MapEntry<int, int>>[];
    queue.add(MapEntry(x, y));

    while (queue.isNotEmpty) {
      final point = queue.removeAt(0); // This is the inefficiency
      final px = point.key;
      final py = point.value;

      final key = '$px,$py';
      if (px < 0 ||
          px >= image.width ||
          py < 0 ||
          py >= image.height ||
          visited.contains(key)) {
        continue;
      }

      final pixelColor = getPixelColor(image, px, py);
      if (pixelColor == null || pixelColor.value != sourceColor.value) {
        continue;
      }

      image.setPixel(
        px,
        py,
        img.ColorRgba8(
          targetColor.red,
          targetColor.green,
          targetColor.blue,
          targetColor.alpha,
        ),
      );
      visited.add(key);

      queue.add(MapEntry(px + 1, py));
      queue.add(MapEntry(px - 1, py));
      queue.add(MapEntry(px, py + 1));
      queue.add(MapEntry(px, py - 1));
    }
}

void fillOptimized(img.Image image, int x, int y, Color targetColor) {
    final sourceColor = getPixelColor(image, x, y);
    if (sourceColor == null) return;
    if (sourceColor.value == targetColor.value) return;

    final visited = <String>{};
    final queue = Queue<MapEntry<int, int>>();
    queue.add(MapEntry(x, y));

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final px = point.key;
      final py = point.value;

      final key = '$px,$py';
      if (px < 0 ||
          px >= image.width ||
          py < 0 ||
          py >= image.height ||
          visited.contains(key)) {
        continue;
      }

      final pixelColor = getPixelColor(image, px, py);
      if (pixelColor == null || pixelColor.value != sourceColor.value) {
        continue;
      }

      image.setPixel(
        px,
        py,
        img.ColorRgba8(
          targetColor.red,
          targetColor.green,
          targetColor.blue,
          targetColor.alpha,
        ),
      );
      visited.add(key);

      queue.add(MapEntry(px + 1, py));
      queue.add(MapEntry(px - 1, py));
      queue.add(MapEntry(px, py + 1));
      queue.add(MapEntry(px, py - 1));
    }
}
