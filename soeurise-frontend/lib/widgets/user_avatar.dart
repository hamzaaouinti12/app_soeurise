import 'package:flutter/material.dart';
import '../constants.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String username;
  final double radius;

  const UserAvatar({
    required this.imageUrl,
    required this.username,
    this.radius = 24,
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

    if (imageUrl == null ||
        imageUrl!.isEmpty ||
        imageUrl!.contains('placeholder')) {
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

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.beige,
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (exception, stackTrace) {},
      child: Container(),
    );
  }
}
