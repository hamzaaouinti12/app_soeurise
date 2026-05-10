import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../screens/user_profile_screen.dart';
import '../theme/glass_widgets.dart';
import '../services/profile_service.dart';
import '../services/post_service.dart';
import 'user_avatar.dart';
import 'content_image.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late int likes;
  bool _isLiked = false;
  bool _isFollowing = false;
  bool _followRequestSent = false;
  bool _isFollowBusy = false;
  late AnimationController _likeController;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    likes = widget.post.likes;
    _isLiked = widget.post.isLiked;
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_likeController);
    _isFollowing =
        ProfileService.instance.getFollowState(widget.post.authorId) ?? false;
    _followRequestSent =
        ProfileService.instance.getFollowRequestSent(widget.post.authorId);
    _loadFollowState();
    ProfileService.instance.followStates.addListener(_syncFollowState);
    ProfileService.instance.followRequestSentStates.addListener(_syncFollowRequestSent);
  }

  @override
  void dispose() {
    ProfileService.instance.followStates.removeListener(_syncFollowState);
    ProfileService.instance.followRequestSentStates.removeListener(_syncFollowRequestSent);
    _likeController.dispose();
    super.dispose();
  }

  void _syncFollowState() {
    final next = ProfileService.instance.getFollowState(widget.post.authorId);
    if (next != null && mounted && next != _isFollowing) {
      setState(() => _isFollowing = next);
    }
  }

  void _syncFollowRequestSent() {
    final next =
        ProfileService.instance.getFollowRequestSent(widget.post.authorId);
    if (mounted && next != _followRequestSent) {
      setState(() => _followRequestSent = next);
    }
  }

  Future<void> _loadFollowState() async {
    if (widget.post.authorId.isEmpty ||
        widget.post.authorId == ProfileService.instance.profile.value.id) {
      return;
    }
    final cached = ProfileService.instance.getFollowState(widget.post.authorId);
    if (cached != null) return;
    final user = await ProfileService.instance.fetchUserProfile(widget.post.authorId);
    if (mounted && user != null) {
      setState(() {
        _isFollowing = user.isFollowing;
        _followRequestSent = user.followRequestSent;
      });
    }
  }

  void _toggleLike() {
    PostService.instance.toggleLike(widget.post.id);
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        likes++;
        _likeController.forward(from: 0);
      } else {
        likes--;
      }
    });
  }

  void _toggleFollow() async {
    if (_isFollowBusy) return;
    setState(() => _isFollowBusy = true);
    final result = await ProfileService.instance.toggleFollowUser(
      widget.post.authorId,
    );
    if (result != null && mounted) {
      setState(() {
        _isFollowing = result.isFollowing;
        _followRequestSent = result.followRequestSent;
      });
    }
    if (mounted) setState(() => _isFollowBusy = false);
  }

  void _sharePost() {
    PostService.instance.sharePost(widget.post.id);
    setState(() => widget.post.shares++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post partagé !'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _repost() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post republié !'),
        backgroundColor: AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _CommentsSheet(
            post: widget.post,
            onCommentAdded: () {
              setState(() => widget.post.comments++);
            },
            onCommentsCountChanged: (count) {
              setState(() => widget.post.comments = count);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                UserProfileScreen(userId: widget.post.authorId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child:
                              widget.post.authorId ==
                                      ProfileService.instance.profile.value.id
                                  ? CurrentUserAvatar(radius: 20)
                                  : UserAvatar(
                                    imageUrl: widget.post.profileImageUrl,
                                    username: widget.post.username,
                                    radius: 20,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            widget.post.authorId ==
                                    ProfileService.instance.profile.value.id
                                ? ValueListenableBuilder<Profile>(
                                  valueListenable:
                                      ProfileService.instance.profile,
                                  builder: (context, profile, _) {
                                    return Text(
                                      profile.fullName,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                )
                                : Text(
                                  widget.post.username,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            const SizedBox(height: 4),
                            Text(
                              'Il y a ${_getTimeAgo(widget.post.timestamp)}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.post.authorId.isNotEmpty &&
                  widget.post.authorId != ProfileService.instance.profile.value.id) ...[
                GestureDetector(
                  onTap: _isFollowBusy ? null : _toggleFollow,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (_isFollowing || _followRequestSent)
                              ? AppColors.primary.withAlpha(20)
                              : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                      border:
                          (_isFollowing || _followRequestSent)
                              ? Border.all(color: AppColors.primary)
                              : null,
                    ),
                    child: Text(
                      _isFollowBusy
                          ? '...'
                          : (_isFollowing
                              ? 'Suivi'
                              : (_followRequestSent ? 'Demandé' : 'Suivre')),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (_isFollowing || _followRequestSent)
                            ? AppColors.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(Icons.more_horiz_rounded, color: AppColors.textLight),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            widget.post.content,
            style: AppTextStyles.bodyLarge.copyWith(fontSize: 14, height: 1.5),
          ),

          // Image
          if (widget.post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: ContentImage(imageUrl: widget.post.imageUrl, height: 200),
            ),
          ] else if (widget.post.localImageFile != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: Image.file(
                widget.post.localImageFile!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Divider
          Container(height: 1, color: AppColors.beigeDark.withAlpha(40)),

          const SizedBox(height: 10),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Like
              GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _likeScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _likeScale.value,
                          child: child,
                        );
                      },
                      child: Icon(
                        _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 22,
                        color:
                            _isLiked ? AppColors.primary : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$likes',
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            _isLiked ? AppColors.primary : AppColors.textLight,
                        fontWeight:
                            _isLiked ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Comment
              GestureDetector(
                onTap: _openComments,
                child: _actionItem(
                  Icons.chat_bubble_outline_rounded,
                  '${widget.post.comments}',
                ),
              ),
              // Repost
              GestureDetector(
                onTap: _repost,
                child: _actionItem(Icons.repeat_rounded, ''),
              ),
              // Share
              GestureDetector(
                onTap: _sharePost,
                child: _actionItem(
                  Icons.share_outlined,
                  '${widget.post.shares}',
                ),
              ),
              // Notification bell
              GestureDetector(
                onTap: () {},
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textLight),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(count, style: AppTextStyles.bodySmall),
        ],
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'à l\'instant';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}j';
    }
  }
}

// ──────────────── Comments Bottom Sheet ────────────────

class _CommentsSheet extends StatefulWidget {
  final Post post;
  final VoidCallback onCommentAdded;
  final Function(int) onCommentsCountChanged;

  const _CommentsSheet({
    required this.post,
    required this.onCommentAdded,
    required this.onCommentsCountChanged,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int get _totalLikes {
    int total = 0;
    for (var c in _comments) {
      total += c.likesCount;
      for (var r in c.replies) {
        total += r.likesCount;
      }
    }
    return total;
  }

  Future<void> _loadComments() async {
    final comments = await PostService.instance.fetchComments(widget.post.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();

    if (_replyingToId != null) {
      final reply = await PostService.instance.replyToComment(
        widget.post.id,
        _replyingToId!,
        text,
      );
      if (reply != null) {
        setState(() {
          final parent = _comments.firstWhere(
            (c) => c.id == _replyingToId,
            orElse: () => _comments.first,
          );
          parent.replies = [...parent.replies, reply];
          _replyingToId = null;
          _replyingToName = null;
        });
      }
    } else {
      final comment = await PostService.instance.addComment(
        widget.post.id,
        text,
      );
      if (comment != null) {
        setState(() => _comments.insert(0, comment));
        widget.onCommentAdded();
      }
    }
  }

  void _likeComment(Comment comment) async {
    final success = await PostService.instance.likeComment(
      widget.post.id,
      comment.id,
    );
    if (success && mounted) {
      setState(() {
        comment.isLiked = !comment.isLiked;
        comment.likesCount += comment.isLiked ? 1 : -1;
      });
    }
  }

  void _setReplyTarget(Comment comment) {
    if (widget.post.commentsDisabled) return;
    setState(() {
      _replyingToId = comment.id;
      _replyingToName = comment.authorName;
    });
    _commentController.clear();
  }

  Future<void> _deleteComment(Comment comment) async {
    print('Attempting to delete comment ${comment.id} from post ${widget.post.id}');
    final success = await PostService.instance.deleteComment(
      widget.post.id,
      comment.id,
    );
    print('Delete success: $success');
    if (success && mounted) {
      setState(() {
        // Try removing from top level
        final countBefore = _comments.length;
        _comments.removeWhere((c) => c.id == comment.id);
        
        // If not found at top level, search in replies
        if (_comments.length == countBefore) {
          for (var parent in _comments) {
            parent.replies.removeWhere((r) => r.id == comment.id);
          }
        }
        widget.onCommentsCountChanged(_comments.length);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commentaire supprimé'), backgroundColor: AppColors.successColor),
      );
    }
  }

  Future<void> _toggleHideComment(Comment comment) async {
    print('Attempting to toggle hide for comment ${comment.id}');
    final success = await PostService.instance.toggleHideComment(
      widget.post.id,
      comment.id,
    );
    print('Toggle hide success: $success');
    if (success && mounted) {
      setState(() {
        comment.isHidden = !comment.isHidden;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(comment.isHidden ? 'Commentaire masqué' : 'Commentaire affiché')),
      );
    }
  }

  Future<void> _togglePinComment(Comment comment) async {
    final success = await PostService.instance.togglePinComment(
      widget.post.id,
      comment.id,
    );
    if (success && mounted) {
      setState(() {
        final wasPinned = comment.isPinned;
        if (!wasPinned) {
          for (var c in _comments) {
            c.isPinned = false;
          }
        }
        comment.isPinned = !wasPinned;
        
        // Re-sort
        _comments.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(comment.isPinned ? 'Commentaire épinglé' : 'Commentaire désépinglé')),
      );
    }
  }

  Future<void> _editComment(Comment comment) async {
    final editController = TextEditingController(text: comment.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le commentaire'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Votre commentaire...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (newContent != null && newContent.isNotEmpty && mounted) {
      final success = await PostService.instance.updateComment(
        widget.post.id,
        comment.id,
        newContent,
      );
      if (success) {
        setState(() {
          // Find and update the comment (could be a reply)
          _updateCommentContent(_comments, comment.id, newContent);
        });
      }
    }
  }

  void _updateCommentContent(List<Comment> list, String id, String content) {
    for (var c in list) {
      if (c.id == id) {
        // We need a way to update the content, but Comment fields are final in the current model.
        // I should have made them non-final or use a copyWith.
        // For now, I'll assume I can't mutate final fields, so I'll replace the object if needed.
        // Actually, looking at the model, only 'likesCount' and 'isLiked' are not final.
        // I'll update the model later if needed, but for now I'll use a hack or just refresh.
        _loadComments(); 
        return;
      }
      if (c.replies.isNotEmpty) {
        _updateCommentContent(c.replies, id, content);
      }
    }
  }

  Future<void> _toggleCommentsDisabled() async {
    final success = await PostService.instance.toggleCommentsDisabled(widget.post.id);
    if (success && mounted) {
      setState(() {
        widget.post.commentsDisabled = !widget.post.commentsDisabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building _CommentsSheet with ${_comments.length} comments. Disabled: ${widget.post.commentsDisabled}');
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.beigeDark.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Commentaires',
                    style: AppTextStyles.headline3.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_comments.length})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalLikes',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.post.authorId == ProfileService.instance.profile.value.id)
                  IconButton(
                    icon: Icon(
                      widget.post.commentsDisabled ? Icons.comments_disabled_rounded : Icons.comment_rounded,
                      color: widget.post.commentsDisabled ? AppColors.textLight : AppColors.primary,
                      size: 20,
                    ),
                    onPressed: _toggleCommentsDisabled,
                    tooltip: widget.post.commentsDisabled ? 'Activer les commentaires' : 'Désactiver les commentaires',
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : _comments.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun commentaire',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Soyez le premier à commenter !',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _comments.length,
                      itemBuilder:
                          (ctx, i) =>
                              _buildCommentTile(_comments[i], isReply: false),
                    ),
          ),

          if (_replyingToName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: AppColors.primary.withAlpha(15),
              child: Row(
                children: [
                  Text(
                    'Répondre à $_replyingToName',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap:
                        () => setState(() {
                          _replyingToId = null;
                          _replyingToName = null;
                        }),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Disabled message
          if (widget.post.commentsDisabled)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              color: AppColors.beigeDark.withAlpha(20),
              child: Center(
                child: Text(
                  'Les commentaires sont désactivés.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                ),
              ),
            ),

          // Input field
          if (!widget.post.commentsDisabled)
            Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8 + bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText:
                          _replyingToName != null
                              ? 'Répondre à $_replyingToName...'
                              : 'Écrire un commentaire...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.beigeDark.withAlpha(60),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.beigeDark.withAlpha(60),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment, {required bool isReply}) {
    final currentUserId = ProfileService.instance.profile.value.id;
    final isPostOwner = widget.post.authorId == currentUserId;
    final isCommentAuthor = comment.authorId == currentUserId;

    return Opacity(
      opacity: comment.isHidden ? 0.5 : 1.0,
      child: Padding(
        padding: EdgeInsets.only(left: isReply ? 40 : 0, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comment.isPinned)
              Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin_rounded, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      'Commentaire épinglé',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  imageUrl: comment.authorAvatar,
                  username: comment.authorName,
                  radius: isReply ? 14 : 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + time + actions
                      Row(
                        children: [
                          Text(
                            comment.authorName,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isReply ? 12 : 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getTimeAgo(comment.createdAt),
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                          if (comment.isHidden) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.visibility_off_rounded, size: 12, color: AppColors.textLight),
                          ],
                          const Spacer(),
                          if (isPostOwner || isCommentAuthor)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz_rounded, size: 18),
                              onSelected: (val) async {
                                try {
                                  print('Comment action selected: $val for comment ${comment.id}');
                                  if (val == 'delete') await _deleteComment(comment);
                                  if (val == 'hide') await _toggleHideComment(comment);
                                  if (val == 'pin') await _togglePinComment(comment);
                                  if (val == 'edit') await _editComment(comment);
                                } catch (e) {
                                  print('Error in onSelected: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (isCommentAuthor)
                                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                if (isPostOwner && !isReply)
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Text(comment.isPinned ? 'Désépingler' : 'Épingler'),
                                  ),
                                PopupMenuItem(
                                  value: 'hide',
                                  child: Text(comment.isHidden ? 'Afficher' : 'Masquer'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Comment text
                      Text(
                        comment.content,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: isReply ? 12.5 : 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Actions
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _likeComment(comment),
                            child: Row(
                              children: [
                                Icon(
                                  comment.isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 16,
                                  color:
                                      comment.isLiked
                                          ? AppColors.primary
                                          : AppColors.textLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likesCount}',
                                  style: AppTextStyles.caption.copyWith(
                                    color:
                                        comment.isLiked
                                            ? AppColors.primary
                                            : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!widget.post.commentsDisabled && !isReply) ...[
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _setReplyTarget(comment),
                              child: Text(
                                'Répondre',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isReply && comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: comment.replies
                      .map((r) => _buildCommentTile(r, isReply: true))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
