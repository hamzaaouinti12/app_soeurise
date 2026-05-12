import 'package:flutter/material.dart';

import 'adaptive_vm_disk_image_stub.dart'
    if (dart.library.io) 'adaptive_vm_disk_image_io.dart' as vm_disk;

/// [Image.file] uniquement sur VM ; stub sur Web (inutilisé si [kIsWeb] côté appelant).
Widget adaptiveVmDiskImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  required Widget Function() placeholder,
}) {
  return vm_disk.buildAdaptiveVmDiskImage(
    path: path,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    placeholder: placeholder,
  );
}
