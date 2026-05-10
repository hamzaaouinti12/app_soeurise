import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/story_service.dart';
import '../services/profile_service.dart';
import '../widgets/user_avatar.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  StoryViewerScreen({required this.stories, this.initialIndex = 0, super.key})
    : assert(stories.isNotEmpty, 'At least one story is required');

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  VideoPlayerController? _videoController;
  PageController? _pageController;
  bool _isVideoReady = false;
  int _currentIndex = 0;
  String _selectedReaction = '';

  static const _reactions = ['❤️', '🔥', '👍', '👏', '😮'];

  Story get _story => widget.stories[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _markViewed();
    if (_story.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _disposeVideoController();
    _videoController = VideoPlayerController.network(_story.mediaUrl)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isVideoReady = true;
        });
        _videoController?.play();
      });
  }

  Future<void> _markViewed() async {
    await StoryService.instance.addView(_story.id);
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeVideoController();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _sendReaction(String reaction) async {
    final success = await StoryService.instance.reactToStory(
      _story.id,
      reaction,
    );
    if (success && mounted) {
      setState(() {
        _selectedReaction = reaction;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réaction envoyée $reaction'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteStory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la story'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette story ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final (success, errorMessage) = await StoryService.instance.deleteStory(_story.id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Story supprimée')));
        Navigator.of(context).pop(); // Retour à l'écran précédent
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: ${errorMessage ?? 'Erreur inconnue'}')),
        );
      }
    }
  }

  bool get _isCurrentUserAuthor {
    final currentUserId = ProfileService.instance.profile.value.id;
    return currentUserId.isNotEmpty && currentUserId == _story.authorId;
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    _disposeVideoController();
    setState(() {
      _currentIndex = index;
      _isVideoReady = false;
    });
    if (_story.isVideo) {
      _initializeVideo();
    }
    _markViewed();
  }

  void _changeStory(int delta) {
    final newIndex = _currentIndex + delta;
    if (newIndex < 0 || newIndex >= widget.stories.length) return;
    _pageController?.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildMedia(Story story) {
    if (story.isVideo) {
      if (story.id == _story.id) {
        if (!_isVideoReady) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return Center(
          child: AspectRatio(
            aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
            child: VideoPlayer(_videoController!),
          ),
        );
      }
      return Container(color: Colors.black);
    }

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Image.network(
        story.mediaUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Impossible de charger l’image',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.stories.length, (index) {
            final bool selected = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: selected ? 26 : 12,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? Colors.black54 : Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white38,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            UserAvatar(
              imageUrl: _story.profileImageUrl,
              username: _story.username,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _story.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions:
            _isCurrentUserAuthor
                ? [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _deleteStory,
                    tooltip: 'Supprimer la story',
                  ),
                ]
                : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: PageView.builder(
                itemCount: widget.stories.length,
                onPageChanged: _onPageChanged,
                controller: _pageController,
                itemBuilder: (context, index) {
                  return _buildMedia(widget.stories[index]);
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildNavigationIndicator(),
          ),
          if (widget.stories.length > 1) ...[
            Positioned(
              left: 16,
              top: MediaQuery.of(context).size.height * 0.45,
              child: _buildArrowButton(
                Icons.arrow_back_ios,
                _currentIndex > 0,
                () => _changeStory(-1),
              ),
            ),
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.45,
              child: _buildArrowButton(
                Icons.arrow_forward_ios,
                _currentIndex < widget.stories.length - 1,
                () => _changeStory(1),
              ),
            ),
          ],
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_story.caption.isNotEmpty) ...[
                    Text(
                      _story.caption,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Vues : ${_story.viewsCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children:
                        _reactions.map((reaction) {
                          final bool selected = _selectedReaction == reaction;
                          return GestureDetector(
                            onTap: () => _sendReaction(reaction),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? AppColors.primary
                                        : AppColors.beige.withAlpha(40),
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.xl,
                                ),
                              ),
                              child: Text(
                                reaction,
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expire le ${_story.expiresAt.toLocal().toString().split('.').first}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
