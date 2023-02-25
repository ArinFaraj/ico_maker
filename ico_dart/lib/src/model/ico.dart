// ignore_for_file: public_member_api_docs, cascade_invocations

import 'dart:typed_data';

class IcoFile {
  IcoFile({required this.header, required this.directoryEntries});
  factory IcoFile.fromBytes(Uint8List bytes) {
    final data = bytes.buffer.asByteData();
    final header = IcoHeader.fromBytes(data);
    final directoryEntries = <IconDirectoryEntry>[];
    var offset = IcoHeader.headerSize;

    for (var i = 0; i < header.numImages; i++) {
      final directoryEntry = IconDirectoryEntry.fromBytes(data, offset);
      directoryEntries.add(directoryEntry);
      offset += IconDirectoryEntry.entrySize;
    }

    return IcoFile(header: header, directoryEntries: directoryEntries);
  }
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

  final IcoHeader header;
  final List<IconDirectoryEntry> directoryEntries;
}

class IcoHeader {
  IcoHeader({
    required this.reserved,
    required this.imageType,
    required this.numImages,
  });
  factory IcoHeader.fromBytes(ByteData bytes) {
    final reserved = bytes.getUint16(0, Endian.little);
    final imageType = bytes.getUint16(2, Endian.little);
    final numImages = bytes.getUint16(4, Endian.little);

    return IcoHeader(
      reserved: reserved,
      imageType: imageType,
      numImages: numImages,
    );
  }
  static const headerSize = 6;
  Uint8List toBytes() {
    final bytes = ByteData(headerSize);
    bytes.setUint16(0, reserved, Endian.little);
    bytes.setUint16(2, imageType, Endian.little);
    bytes.setUint16(4, numImages, Endian.little);
    return bytes.buffer.asUint8List();
  }

  final int reserved;
  final int imageType;
  final int numImages;
}

class IconDirectoryEntry {
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
  static const entrySize = 16;
  List<int> toBytes() {
    final bytes = ByteData(entrySize);
    bytes.setUint8(0, width);
    bytes.setUint8(1, height);
    bytes.setUint8(2, colorCount);
    bytes.setUint8(3, reserved);
    bytes.setUint16(4, numPlanes, Endian.little);
    bytes.setUint16(6, bitsPerPixel, Endian.little);
    bytes.setUint32(8, imageSize, Endian.little);
    bytes.setUint32(12, imageOffset, Endian.little);

    return bytes.buffer.asUint8List();
  }

  final int width;
  final int height;
  final int colorCount;
  final int reserved;
  final int numPlanes;
  final int bitsPerPixel;
  final int imageSize;
  final int imageOffset;
  final Uint8List imageData;
}
