// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  // Convert PNG bytes to an Image object
  static img.Image? bytesToImage(Uint8List bytes) {
    try {
      return img.decodePng(bytes);
    } catch (e) {
      debugPrint('Error decoding image: $e');
      return null;
    }
  }

  // Convert image to PNG bytes
  static Uint8List? imageToPngBytes(img.Image image) {
    try {
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      debugPrint('Error encoding image: $e');
      return null;
    }
  }

  // Resize image to specific dimensions
  static img.Image resizeImage(img.Image image, int width, int height) {
    return img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.cubic,
    );
  }

  // Create a transparent image with specified dimensions
  static img.Image createEmptyImage(int width, int height) {
    return img.Image(width: width, height: height, numChannels: 4);
  }

  // Draw image onto another image at specified position
  static img.Image drawImageOnCanvas(
    img.Image canvas,
    img.Image source,
    int x,
    int y,
  ) {
    return img.compositeImage(canvas, source, dstX: x, dstY: y);
  }

  // Create a color image
  static img.Image createColorImage(int width, int height, Color color) {
    final image = img.Image(width: width, height: height, numChannels: 4);

    img.fill(
      image,
      color: img.ColorRgba8(color.red, color.green, color.blue, color.alpha),
    );

    return image;
  }

  // Draw a rectangle on an image
  static img.Image drawRectangle(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    Color color, {
    bool filled = false,
  }) {
    final result = img.Image.from(image);
    final imgColor = img.ColorRgba8(
      color.red,
      color.green,
      color.blue,
      color.alpha,
    );

    if (filled) {
      for (var py = y; py < y + height; py++) {
        for (var px = x; px < x + width; px++) {
          if (px >= 0 && px < result.width && py >= 0 && py < result.height) {
            result.setPixel(px, py, imgColor);
          }
        }
      }
    } else {
      // Draw horizontal lines
      for (var px = x; px < x + width; px++) {
        if (px >= 0 && px < result.width) {
          if (y >= 0 && y < result.height) {
            result.setPixel(px, y, imgColor);
          }
          if (y + height - 1 >= 0 && y + height - 1 < result.height) {
            result.setPixel(px, y + height - 1, imgColor);
          }
        }
      }

      // Draw vertical lines
      for (var py = y; py < y + height; py++) {
        if (py >= 0 && py < result.height) {
          if (x >= 0 && x < result.width) {
            result.setPixel(x, py, imgColor);
          }
          if (x + width - 1 >= 0 && x + width - 1 < result.width) {
            result.setPixel(x + width - 1, py, imgColor);
          }
        }
      }
    }

    return result;
  }

  // Draw a line on an image using Bresenham's algorithm
  static img.Image drawLine(
    img.Image image,
    int x1,
    int y1,
    int x2,
    int y2,
    Color color, {
    int thickness = 1,
  }) {
    final result = img.Image.from(image);
    final imgColor = img.ColorRgba8(
      color.red,
      color.green,
      color.blue,
      color.alpha,
    );

    // Bresenham's algorithm
    int dx = (x2 - x1).abs();
    int dy = (y2 - y1).abs();
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;

    while (true) {
      // Draw pixel if in bounds
      if (x1 >= 0 && x1 < result.width && y1 >= 0 && y1 < result.height) {
        result.setPixel(x1, y1, imgColor);

        // Draw thickness (simple approach for now)
        for (int t = 1; t < thickness; t++) {
          if (dx > dy) {
            // More horizontal, add thickness vertically
            if (y1 + t < result.height) result.setPixel(x1, y1 + t, imgColor);
            if (y1 - t >= 0) result.setPixel(x1, y1 - t, imgColor);
          } else {
            // More vertical, add thickness horizontally
            if (x1 + t < result.width) result.setPixel(x1 + t, y1, imgColor);
            if (x1 - t >= 0) result.setPixel(x1 - t, y1, imgColor);
          }
        }
      }

      if (x1 == x2 && y1 == y2) break;
      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x1 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y1 += sy;
      }
    }

    return result;
  }

  // Get a color at an (x,y) position in the image
  static Color? getPixelColor(img.Image image, int x, int y) {
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

  // Set a pixel color at an (x,y) position
  static img.Image setPixelColor(img.Image image, int x, int y, Color color) {
    if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
      return image;
    }

    final result = img.Image.from(image);
    result.setPixel(
      x,
      y,
      img.ColorRgba8(color.red, color.green, color.blue, color.alpha),
    );

    return result;
  }
}
