import 'dart:io';
import 'package:ico_dart/ico_dart.dart';
import 'package:test/test.dart';

void main() {
  test('benchmark toBytes', () {
    final bytes = File('test/assets/icon.ico').readAsBytesSync();
    final file = IcoFile.fromBytes(bytes);

    // Warmup
    for (var i = 0; i < 100; i++) {
      file.toBytes();
    }

    final stopwatch = Stopwatch()..start();
    const iterations = 1000;
    for (var i = 0; i < iterations; i++) {
      file.toBytes();
    }
    stopwatch.stop();

    print('Benchmark result: ${stopwatch.elapsedMilliseconds} ms for $iterations iterations');
  });
}
