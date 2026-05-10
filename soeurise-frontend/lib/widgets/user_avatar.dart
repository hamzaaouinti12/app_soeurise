import 'dart:io';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/profile_service.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String username;
  final double radius;
  final File? localFile;

  const UserAvatar({
    required this.imageUrl,
    required this.username,
    this.radius = 24,
    this.localFile,
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

    // Prioritize local file (for immediate feedback after picking)
    if (localFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.beige,
        backgroundImage: FileImage(localFile!),
      );
    }

    if (imageUrl == null ||
        imageUrl!.isEmpty ||
        imageUrl!.contains('placeholder')) {
      return _buildInitialsAvatar(initials);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.beige,
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        // Fallback to initials on network error
      },
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialsAvatar(initials),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
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
          localFile: profile.profileImageFile,
        );
      },
    );
  }
}
