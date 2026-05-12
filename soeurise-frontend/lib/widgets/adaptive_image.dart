import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'adaptive_vm_disk_image.dart';

/// Affiche une image : réseau, asset, mémoire, chemin local (disque VM / URL Web), ou objet [.path] (legacy).
class AdaptiveImage extends StatelessWidget {
  final dynamic file;
  final Uint8List? memoryBytes;
  final String? imageUrl;
  final String? assetName;
  /// Fichier disque (mobile) ou URL `blob:` / `http` (web) sans passer par [file].
  final String? localPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  const AdaptiveImage({
    this.file,
    this.memoryBytes,
    this.imageUrl,
    this.assetName,
    this.localPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  static bool _canLoadPathAsNetwork(String path) {
    final p = path.trim();
    return p.startsWith('http://') ||
        p.startsWith('https://') ||
        p.startsWith('blob:') ||
        p.startsWith('data:');
  }

  Widget _networkImage(String url) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _fromResolvedPath(String rawPath) {
    final p = rawPath.trim();
    if (p.isEmpty) return _buildPlaceholder();
    if (kIsWeb) {
      if (_canLoadPathAsNetwork(p)) return _networkImage(p);
      return _buildPlaceholder();
    }
    return adaptiveVmDiskImage(
      path: p,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      placeholder: _buildPlaceholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return _networkImage(imageUrl!.trim());
    }
    if (assetName != null && assetName!.trim().isNotEmpty) {
      return Image.asset(
        assetName!.trim(),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    if (memoryBytes != null && memoryBytes!.isNotEmpty) {
      return Image.memory(
        memoryBytes!,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    if (localPath != null && localPath!.trim().isNotEmpty) {
      return _fromResolvedPath(localPath!);
    }
    if (file != null) {
      final path = (file as dynamic).path as String?;
      if (path != null && path.trim().isNotEmpty) {
        return _fromResolvedPath(path);
      }
      return _buildPlaceholder();
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
      ),
    );
  }
}
