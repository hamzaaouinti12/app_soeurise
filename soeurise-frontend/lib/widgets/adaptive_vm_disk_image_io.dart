import 'dart:io' as io;

import 'package:flutter/material.dart';

Widget buildAdaptiveVmDiskImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  required Widget Function() placeholder,
}) {
  return Image.file(
    io.File(path),
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    errorBuilder: (context, error, stackTrace) => placeholder(),
  );
}
