// ignore_for_file: prefer_const_constructors
import 'dart:developer';
import 'dart:io';

import 'package:ico_dart/ico_dart.dart';
import 'package:test/test.dart';

void main() {
  group('IcoDart', () {
    test('read icon file from bytes', () {
      // Read the file from the disk
      final bytes = File('test/assets/icon.ico').readAsBytesSync();
      final file = IcoFile.fromBytes(bytes);
      expect(file, isNotNull);
    });

    test('read icon file then save it back', () {
      // Read the file from the disk
      final bytes = File('test/assets/icon.ico').readAsBytesSync();
      final file = IcoFile.fromBytes(bytes);
      expect(file, isNotNull);

      // Save the file back to the disk
      final newBytes = file.toBytes();
      File('test/assets/icon2.ico').writeAsBytesSync(newBytes);
      log('newBytes: ${newBytes.length}, oldBytes: ${bytes.length}');
      for (var i = 0; i < bytes.length; i++) {
        expect(bytes[i], newBytes[i], reason: 'byte $i is different');
      }
    });
  });
}
