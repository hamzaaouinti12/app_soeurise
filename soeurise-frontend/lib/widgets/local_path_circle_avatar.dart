import 'package:flutter/material.dart';

import '../constants.dart';
import 'local_path_circle_avatar_stub.dart'
    if (dart.library.io) 'local_path_circle_avatar_io.dart' as lp_impl;

/// Avatar depuis un chemin disque (VM) ou URL/blob (Web).
Widget localPathCircleAvatar({
  required String path,
  required double radius,
}) {
  return lp_impl.buildLocalPathCircleAvatar(
    path: path,
    radius: radius,
    background: AppColors.beige,
  );
}
