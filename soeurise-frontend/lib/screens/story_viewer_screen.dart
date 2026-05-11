import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/story_service.dart';
import '../services/profile_service.dart';
import '../services/message_service.dart';
import '../widgets/user_avatar.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  StoryViewerScreen({required this.stories, this.initialIndex = 0, super.key})
    : assert(stories.isNotEmpty, 'At least one story is required');

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  PageController? _pageController;
  late AnimationController _progressController;
  bool _isVideoReady = false;
  int _currentIndex = 0;
  String _selectedReaction = '';
  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;
  static const Duration _defaultStoryDuration = Duration(seconds: 6);
  static const _quickReplies = ['😍', '😂', '🔥', '👏', '💯'];
  double _verticalDrag = 0;

  static const _reactions = ['❤️', '🔥', '👍', '👏', '😮'];

  Story get _story => widget.stories[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(vsync: this);
    _markViewed();
    _configureStoryPlayback();
  }

  void _configureStoryPlayback() {
    _progressController.stop();
    _progressController.reset();

    if (_story.isVideo) {
      _initializeVideo();
    } else {
      _startProgress(_defaultStoryDuration);
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
        final duration = _videoController?.value.duration;
        _startProgress(duration ?? _defaultStoryDuration);
      });
  }

  void _startProgress(Duration duration) {
    _progressController.removeStatusListener(_onProgressStatus);
    _progressController.duration = duration;
    _progressController.forward(from: 0);
    _progressController.addStatusListener(_onProgressStatus);
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _progressController.removeStatusListener(_onProgressStatus);
    if (_currentIndex < widget.stories.length - 1) {
      _changeStory(1);
    } else {
      Navigator.pop(context);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _verticalDrag += details.primaryDelta ?? 0;
    if (_verticalDrag.abs() > 120) {
      Navigator.pop(context);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _verticalDrag = 0;
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
    _progressController.dispose();
    _disposeVideoController();
    _pageController?.dispose();
    _replyController.dispose();
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
    _configureStoryPlayback();
    _markViewed();
  }

  void _changeStory(int delta) {
    final newIndex = _currentIndex + delta;
    if (newIndex < 0 || newIndex >= widget.stories.length) return;
    _progressController.removeStatusListener(_onProgressStatus);
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
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        return Row(
          children: List.generate(widget.stories.length, (index) {
            double progress;
            if (index < _currentIndex) {
              progress = 1;
            } else if (index > _currentIndex) {
              progress = 0;
            } else {
              progress = _progressController.value;
            }

            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSendingReply) return;
    setState(() => _isSendingReply = true);
    final sent = await MessageService.instance.sendTextMessage(
      _story.authorId,
      text,
    );
    if (!mounted) return;
    setState(() => _isSendingReply = false);
    if (sent != null) {
      _replyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoye')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur d\'envoi du message')),
      );
    }
  }

  Future<void> _sendQuickReply(String emoji) async {
    if (_isSendingReply) return;
    setState(() => _isSendingReply = true);
    final sent = await MessageService.instance.sendTextMessage(
      _story.authorId,
      emoji,
    );
    if (!mounted) return;
    setState(() => _isSendingReply = false);
    if (sent != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reaction envoyee $emoji')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur d\'envoi du message')),
      );
    }
  }

  Future<void> _showViewers() async {
    final viewers = await StoryService.instance.fetchViewers(_story.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppBorderRadius.xxl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.beigeDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Vues', style: AppTextStyles.headline3),
                const SizedBox(height: 12),
                if (viewers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aucune vue pour l\'instant',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: viewers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final viewer = viewers[index];
                        return ListTile(
                          leading: UserAvatar(
                            imageUrl: viewer.avatarFullUrl,
                            username: viewer.displayName,
                            radius: 18,
                          ),
                          title: Text(viewer.displayName),
                          subtitle:
                              viewer.viewedAt != null
                                  ? Text(
                                      'Vu le ${viewer.viewedAt!.toLocal().toString().split('.').first}',
                                      style: AppTextStyles.bodySmall,
                                    )
                                  : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
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
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _changeStory(-1),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _changeStory(1),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    children: [
                      _buildNavigationIndicator(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                          if (_isCurrentUserAuthor)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _deleteStory,
                              tooltip: 'Supprimer la story',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(0),
                      Colors.black.withAlpha(120),
                      Colors.black.withAlpha(200),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_story.caption.isNotEmpty) ...[
                      Text(
                        _story.caption,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_isCurrentUserAuthor) ...[
                      Row(
                        children: [
                          Text(
                            'Vues : ${_story.viewsCount}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _showViewers,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Voir les vues',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Wrap(
                      spacing: 8,
                      children:
                          _reactions.map((reaction) {
                            final bool selected = _selectedReaction == reaction;
                            return GestureDetector(
                              onTap: () => _sendReaction(reaction),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      selected
                                          ? AppColors.primary
                                          : Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.xl,
                                  ),
                                ),
                                child: Text(
                                  reaction,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: selected ? Colors.white : Colors.white,
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
                        color: Colors.white70,
                      ),
                    ),
                    if (!_isCurrentUserAuthor) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: _quickReplies
                            .map(
                              (emoji) => GestureDetector(
                                onTap: () => _sendQuickReply(emoji),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.pill,
                                ),
                                border: Border.all(
                                  color: Colors.white.withAlpha(40),
                                ),
                              ),
                              child: TextField(
                                controller: _replyController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Envoyer un message',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendReply,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: _isSendingReply
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
