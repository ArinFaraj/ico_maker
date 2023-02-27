import 'dart:typed_data';

/// A class for parsing ICO files.
class IcoFile {
  /// IcoFile is a class for parsing ICO files.
  IcoFile._({required this.header, required this.directoryEntries});

  /// Creates an [IcoFile] from a [Uint8List].
  factory IcoFile.fromBytes(Uint8List bytes) {
    final data = bytes.buffer.asByteData();
    final header = IcoHeader.fromBytes(data);
    final directoryEntries = <IconDirectoryEntry>[];
    var offset = IcoHeader.headerSize;

    for (var i = 0; i < header.imageCount; i++) {
      final directoryEntry = IconDirectoryEntry.fromBytes(data, offset);
      directoryEntries.add(directoryEntry);
      offset += IconDirectoryEntry.entrySize;
    }

    return IcoFile._(header: header, directoryEntries: directoryEntries);
  }

  /// Creates a [Uint8List] from an [IcoFile].
  Uint8List toBytes() {
    final headerBytes = header.toBytes();
    final directoryBytes = directoryEntries.fold(
      <int>[],
      (bytes, entry) => bytes..addAll(entry.toBytes()),
    );
    final imageBytes = directoryEntries.fold(
      <int>[],
      (bytes, entry) => bytes..addAll(entry.imageData),
    );
    return Uint8List.fromList(
      [...headerBytes, ...directoryBytes, ...imageBytes],
    );
  }

  /// The header of the ICO file.
  final IcoHeader header;

  /// The icon directory entries of the ICO file.
  final List<IconDirectoryEntry> directoryEntries;
}

/// The header of an ICO file.
class IcoHeader {
  /// The header of an ICO file.
  IcoHeader({
    required this.reserved,
    required this.imageType,
    required this.imageCount,
  });

  /// Creates an [IcoHeader] from a [ByteData].
  factory IcoHeader.fromBytes(ByteData bytes) {
    final reserved = bytes.getUint16(0, Endian.little);
    final imageType = bytes.getUint16(2, Endian.little);
    final numImages = bytes.getUint16(4, Endian.little);

    return IcoHeader(
      reserved: reserved,
      imageType: imageType,
      imageCount: numImages,
    );
  }

  /// The size of the header in bytes.
  static const headerSize = 6;

  /// Creates a [Uint8List] from an [IcoHeader].
  Uint8List toBytes() {
    final bytes = ByteData(headerSize)
      ..setUint16(0, reserved, Endian.little)
      ..setUint16(2, imageType, Endian.little)
      ..setUint16(4, imageCount, Endian.little);
    return bytes.buffer.asUint8List();
  }

  /// The reserved field of the header.
  final int reserved;

  /// type of image, 1 for icon, 2 for cursor
  final int imageType;

  /// number of images in the file
  final int imageCount;
}

/// An icon directory entry.
class IconDirectoryEntry {
  /// An icon directory entry.
  IconDirectoryEntry({
    required this.width,
    required this.height,
    required this.colorCount,
    required this.reserved,
    required this.numPlanes,
    required this.bitsPerPixel,
    required this.imageSize,
    required this.imageOffset,
    required this.imageData,
  });

  /// Creates an [IconDirectoryEntry] from a [ByteData].
  factory IconDirectoryEntry.fromBytes(ByteData bytes, int offset) {
    final width = bytes.getUint8(offset);
    final height = bytes.getUint8(offset + 1);
    final colorCount = bytes.getUint8(offset + 2);
    final reserved = bytes.getUint8(offset + 3);
    final numPlanes = bytes.getUint16(offset + 4, Endian.little);
    final bitsPerPixel = bytes.getUint16(offset + 6, Endian.little);
    final imageSize = bytes.getUint32(offset + 8, Endian.little);
    final imageOffset = bytes.getUint32(offset + 12, Endian.little);
    final imageData = bytes.buffer.asUint8List(imageOffset, imageSize);

    return IconDirectoryEntry(
      width: width,
      height: height,
      colorCount: colorCount,
      reserved: reserved,
      numPlanes: numPlanes,
      bitsPerPixel: bitsPerPixel,
      imageSize: imageSize,
      imageOffset: imageOffset,
      imageData: imageData,
    );
  }

  /// The size of the entry in bytes.
  static const entrySize = 16;

  /// Creates a [Uint8List] from an [IconDirectoryEntry].
  Uint8List toBytes() {
    final bytes = ByteData(entrySize)
      ..setUint8(0, width)
      ..setUint8(1, height)
      ..setUint8(2, colorCount)
      ..setUint8(3, reserved)
      ..setUint16(4, numPlanes, Endian.little)
      ..setUint16(6, bitsPerPixel, Endian.little)
      ..setUint32(8, imageSize, Endian.little)
      ..setUint32(12, imageOffset, Endian.little);

    return bytes.buffer.asUint8List();
  }

  /// The width of the image.
  final int width;

  /// The height of the image.
  final int height;

  /// The number of colors in the image.
  final int colorCount;

  /// The reserved field of the entry.
  final int reserved;

  /// The number of planes in the image.
  final int numPlanes;

  /// The number of bits per pixel.
  final int bitsPerPixel;

  /// The size of the image data.
  final int imageSize;

  /// The offset of the image data.
  final int imageOffset;

  /// The image data.
  final Uint8List imageData;
}
