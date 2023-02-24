/// A Windows ICO file.
class IcoFile {
  /// Creates a Windows ICO file.
  IcoFile({required this.images});

  /// Creates a Windows ICO file from a list of bytes.
  factory IcoFile.fromBytes(List<int> bytes) {
    // Check for valid ICO file signature
    if (bytes.length < 6 ||
        bytes[0] != 0x00 ||
        bytes[1] != 0x00 ||
        bytes[2] != 0x01 ||
        bytes[3] != 0x00) {
      throw Exception('Invalid ICO file');
    }
    // Parse header
    final imageType = bytes[2];
    final numImages = bytes[4] + (bytes[5] << 8); // Little-endian byte order

    // Parse image data
    final images = <IcoImage>[];
    var offset = 6; // Offset of first image data

    for (var i = 0; i < numImages; i++) {
      final width = bytes[offset];
      final height = bytes[offset + 1];
      final colorCount = bytes[offset + 2];
      final colorPlanes = bytes[offset + 4];
      final bitsPerPixel = bytes[offset + 6];
      final dataSize = bytes[offset + 8] +
          (bytes[offset + 9] << 8) +
          (bytes[offset + 10] << 16) +
          (bytes[offset + 11] << 24); // Little-endian byte order
      final dataOffset = bytes[offset + 12] +
          (bytes[offset + 13] << 8) +
          (bytes[offset + 14] << 16) +
          (bytes[offset + 15] << 24); // Little-endian byte order

      final imageData = bytes.sublist(dataOffset, dataOffset + dataSize);
      images.add(
        IcoImage(
          width: width,
          height: height,
          colorCount: colorCount,
          colorDepth: bitsPerPixel,
          imageData: imageData,
        ),
      );

      offset += 16; // Move to next image data
    }

    return IcoFile(images: images);
  }

  /// The images in the ICO file.
  List<IcoImage> images;

  /// Converts the ICO file to a list of bytes.
  List<int> toBytes() {
    final header = <int>[0, 0, 1, 0, images.length & 0xFF, images.length >> 8];
    final imageData = <int>[];

    var offset = header.length + images.length * 16;
    for (final image in images) {
      final width = image.width == 256 ? 0 : image.width;
      final height = image.height == 256 ? 0 : image.height;
      final colorCount = image.colorCount <= 256 ? image.colorCount : 0;
      const planes = 1;
      final bpp = image.colorDepth;
      final dataSize = image.imageData.length;

      imageData.addAll([
        width,
        height,
        colorCount,
        0,
        planes,
        bpp,
        dataSize & 0xFF,
        (dataSize >> 8) & 0xFF,
        (dataSize >> 16) & 0xFF,
        (dataSize >> 24) & 0xFF,
        offset & 0xFF,
        (offset >> 8) & 0xFF,
        (offset >> 16) & 0xFF,
        (offset >> 24) & 0xFF,
      ]);

      imageData.addAll(image.imageData);
      offset += dataSize;
    }

    return header + imageData;
  }
}

/// An image in an ICO file.
class IcoImage {
  /// Creates an image in an ICO file.
  IcoImage({
    required this.width,
    required this.height,
    required this.colorDepth,
    required this.colorCount,
    required this.imageData,
  });

  /// The width of the image in pixels.
  int width;

  /// The height of the image in pixels.
  int height;

  /// The number of bits per pixel.
  int colorDepth;

  /// The number of colors in the image.
  int colorCount;

  /// The image data.
  List<int> imageData;
}

/// Converts a list of bytes to an integer.
int bytesToInt32(List<int> bytes) {
  return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
}
