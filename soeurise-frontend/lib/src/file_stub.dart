import 'dart:typed_data';

/// A Web-safe stub for `dart:io`'s `File` class.
///
/// This stub is used only when building for web via conditional imports.
class File {
  final String path;

  File(this.path);

  Future<Uint8List> readAsBytes() {
    return Future.error(UnsupportedError('File.readAsBytes is not supported on web.'));
  }
}
