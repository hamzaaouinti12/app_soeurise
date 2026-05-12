import 'package:flutter/material.dart';

Widget buildLocalPathCircleAvatar({
  required String path,
  required double radius,
  required Color background,
}) {
  final p = path.trim();
  if (p.isEmpty) {
    return CircleAvatar(radius: radius, backgroundColor: background);
  }
  if (p.startsWith('http://') ||
      p.startsWith('https://') ||
      p.startsWith('blob:') ||
      p.startsWith('data:')) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      backgroundImage: NetworkImage(p),
    );
  }
  return CircleAvatar(radius: radius, backgroundColor: background);
}
