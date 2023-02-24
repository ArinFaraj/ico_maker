// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:ico_dart/ico_dart.dart';
import 'package:ico_dart/src/model/ico.dart';
import 'package:test/test.dart';

void main() {
  group('IcoDart', () {
    test('can be instantiated', () {
      expect(IcoDart(), isNotNull);
    });

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

      assert(
        bytes.length == newBytes.length,
        '''
The length of the two files are different ${bytes.length} != ${newBytes.length}''',
      );
    });
  });
}
