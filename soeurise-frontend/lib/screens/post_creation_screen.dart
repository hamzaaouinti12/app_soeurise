import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../models/models.dart';
import '../widgets/user_avatar.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';

class PostCreationScreen extends StatefulWidget {
  final Function(Post)? onPostCreated;

  const PostCreationScreen({super.key, this.onPostCreated});

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  final textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool _isPublishing = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (!mounted) return;
      if (pickedFile != null) {
        setState(() => selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _publishPost() async {
    if (textController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Veuillez entrer du texte')));
      return;
    }

    setState(() => _isPublishing = true);

    final newPost = await PostService.instance.createPost(
      content: textController.text,
      imageFile: selectedImage,
    );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (newPost != null) {
        if (widget.onPostCreated != null) {
          widget.onPostCreated!(newPost);
        }
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du post')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback:
                            (bounds) =>
                                AppColors.accentGradient.createShader(bounds),
                        child: const Text(
                          'Nouvelle publication',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassButton(
                      label: 'Publier',
                      isLoading: _isPublishing,
                      width: 90,
                      onPressed: _publishPost,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // User info
                      FadeSlideIn(
                        child: Row(
                          children: [
                            UserAvatar(
                              imageUrl:
                                  ProfileService
                                      .instance
                                      .profile
                                      .value
                                      .profileImageUrl,
                              username:
                                  ProfileService
                                      .instance
                                      .profile
                                      .value
                                      .fullName,
                              radius: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ProfileService
                                        .instance
                                        .profile
                                        .value
                                        .fullName,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '🌍 Public',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Text field
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: GlassCard(
                          padding: const EdgeInsets.all(4),
                          child: TextField(
                            controller: textController,
                            maxLines: 8,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Qu\'avez-vous en tête ? ✨',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textLight,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ),

                      // Selected image
                      if (selectedImage != null) ...[
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.lg,
                                ),
                                child: Image.file(
                                  selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap:
                                      () =>
                                          setState(() => selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(120),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  border: Border(
                    top: BorderSide(color: AppColors.beigeDark.withAlpha(40)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      _actionButton(Icons.image_rounded, 'Photo', _pickImage),
                      const SizedBox(width: 12),
                      _actionButton(
                        Icons.emoji_emotions_outlined,
                        'Emoji',
                        () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
