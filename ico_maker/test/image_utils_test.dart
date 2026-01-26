import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ico_maker/utils/image_utils.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageUtils.drawRectangle', () {
    test('draws filled rectangle fully inside', () {
      final image = img.Image(width: 10, height: 10, numChannels: 4);
      final color = const Color(0xFFFF0000); // Red

      final result = ImageUtils.drawRectangle(image, 2, 2, 4, 4, color, filled: true);

      // Check a pixel inside (2,2) to (5,5)
      // x: 2, 3, 4, 5. width 4.
      // y: 2, 3, 4, 5. height 4.

      expect(ImageUtils.getPixelColor(result, 2, 2), color, reason: 'Pixel at 2,2 should be red');
      expect(ImageUtils.getPixelColor(result, 5, 5), color, reason: 'Pixel at 5,5 should be red');

      // Check a pixel outside
      final pixelOutside = ImageUtils.getPixelColor(result, 1, 1);
      expect(pixelOutside!.alpha, 0, reason: 'Pixel at 1,1 should be empty');

      final pixelOutside2 = ImageUtils.getPixelColor(result, 6, 6);
      expect(pixelOutside2!.alpha, 0, reason: 'Pixel at 6,6 should be empty');
    });

    test('draws filled rectangle partially outside (top-left)', () {
      final image = img.Image(width: 10, height: 10, numChannels: 4);
      final color = const Color(0xFF0000FF); // Blue

      final result = ImageUtils.drawRectangle(image, -2, -2, 5, 5, color, filled: true);

      // x: -2, -1, 0, 1, 2.
      // visible x: 0, 1, 2.

      expect(ImageUtils.getPixelColor(result, 0, 0), color, reason: 'Pixel at 0,0 should be blue');
      expect(ImageUtils.getPixelColor(result, 2, 2), color, reason: 'Pixel at 2,2 should be blue');

      final pixelOutside = ImageUtils.getPixelColor(result, 3, 3);
      expect(pixelOutside!.alpha, 0, reason: 'Pixel at 3,3 should be empty');
    });

    test('draws filled rectangle fully outside', () {
      final image = img.Image(width: 10, height: 10, numChannels: 4);
      final color = const Color(0xFF00FF00); // Green

      final result = ImageUtils.drawRectangle(image, -10, -10, 5, 5, color, filled: true);

      // Should remain empty
      for(int y=0; y<10; y++) {
        for(int x=0; x<10; x++) {
           expect(ImageUtils.getPixelColor(result, x, y)!.alpha, 0);
        }
      }
    });

    test('draws filled rectangle covering whole image', () {
      final image = img.Image(width: 5, height: 5, numChannels: 4);
      final color = const Color(0xFFFFFF00); // Yellow

      final result = ImageUtils.drawRectangle(image, -5, -5, 20, 20, color, filled: true);

      for(int y=0; y<5; y++) {
        for(int x=0; x<5; x++) {
           expect(ImageUtils.getPixelColor(result, x, y), color);
        }
      }
    });
  });
}
