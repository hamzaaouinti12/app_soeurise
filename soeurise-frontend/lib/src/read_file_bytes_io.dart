import 'dart:io' as io;

Future<List<int>> readFileBytes(String path) =>
    io.File(path).readAsBytes();
