import 'dart:io' as io;

import 'package:flutter/material.dart';

Widget buildLocalPathCircleAvatar({
  required String path,
  required double radius,
  required Color background,
}) {
  return CircleAvatar(
    radius: radius,
    backgroundColor: background,
    backgroundImage: FileImage(io.File(path)),
  );
}
