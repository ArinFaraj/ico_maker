import 'dart:io';

import 'package:ico_dart/ico_dart.dart';

void main(List<String> args) {
  final path = args.first;
  final bytes = File(path).readAsBytesSync();
  final ico = IcoFile.fromBytes(bytes);
  print(ico.header.imageCount);
}
