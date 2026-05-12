import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../services/profile_service.dart';
import 'local_path_circle_avatar.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String username;
  final double radius;
  /// Aperçu local : chemin fichier (mobile) ou URL `blob:`/`http` (web).
  final String? localFilePath;

  const UserAvatar({
    required this.imageUrl,
    required this.username,
    this.radius = 24,
    this.localFilePath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String getInitials(String name) {
      if (name.isEmpty) return '?';
      final words = name.trim().split(RegExp(r'\s+'));
      final initials = words
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase())
          .join();
      if (initials.isEmpty) return '?';
      if (initials.length > 2) return initials.substring(0, 2);
      return initials;
    }

    final initials = getInitials(username);

    final local = localFilePath?.trim();
    if (local != null && local.isNotEmpty) {
      return localPathCircleAvatar(path: local, radius: radius);
    }

    if (imageUrl == null ||
        imageUrl!.isEmpty ||
        imageUrl!.contains('placeholder')) {
      return _buildInitialsAvatar(initials);
    }


    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.beige,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.beige,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _buildInitialsAvatar(initials),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(30),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

/// A reactive avatar for the current logged-in user.
class CurrentUserAvatar extends StatelessWidget {
  final double radius;

  const CurrentUserAvatar({
    this.radius = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Profile>(
      valueListenable: ProfileService.instance.profile,
      builder: (context, profile, _) {
        return UserAvatar(
          imageUrl: profile.profileImageUrlWithCache,
          username: profile.fullName,
          radius: radius,
          localFilePath: profile.profileImageLocalPath,
        );
      },
    );
  }
}
