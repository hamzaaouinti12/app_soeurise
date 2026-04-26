import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../theme/glass_widgets.dart';
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
        tween: Tween(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_likeController);
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
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

  void _toggleFollow() {
    PostService.instance.toggleFollow(widget.post.authorId);
    setState(() => _isFollowing = !_isFollowing);
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
      builder: (ctx) => _CommentsSheet(
        postId: widget.post.id,
        onCommentAdded: () {
          setState(() => widget.post.comments++);
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
                  child: UserAvatar(
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.post.username,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.post.authorId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleFollow,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isFollowing
                                    ? AppColors.primary.withAlpha(20)
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.pill),
                                border: _isFollowing
                                    ? Border.all(color: AppColors.primary)
                                    : null,
                              ),
                              child: Text(
                                _isFollowing ? 'Suivi' : 'Suivre',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isFollowing
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Il y a ${_getTimeAgo(widget.post.timestamp)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textLight,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            widget.post.content,
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 14,
              height: 1.5,
            ),
          ),

          // Image
          if (widget.post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: ContentImage(
                imageUrl: widget.post.imageUrl,
                height: 200,
              ),
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
          Container(
            height: 1,
            color: AppColors.beigeDark.withAlpha(40),
          ),

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
                        color: _isLiked
                            ? AppColors.primary
                            : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$likes',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isLiked
                            ? AppColors.primary
                            : AppColors.textLight,
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
                child: _actionItem(
                  Icons.repeat_rounded,
                  '',
                ),
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
  final String postId;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.postId,
    required this.onCommentAdded,
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

  Future<void> _loadComments() async {
    final comments = await PostService.instance.fetchComments(widget.postId);
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
        widget.postId,
        _replyingToId!,
        text,
      );
      if (reply != null) {
        setState(() {
          final parent = _comments.firstWhere((c) => c.id == _replyingToId, orElse: () => _comments.first);
          parent.replies = [...parent.replies, reply];
          _replyingToId = null;
          _replyingToName = null;
        });
      }
    } else {
      final comment = await PostService.instance.addComment(widget.postId, text);
      if (comment != null) {
        setState(() => _comments.insert(0, comment));
        widget.onCommentAdded();
      }
    }
  }

  void _likeComment(Comment comment) async {
    final success = await PostService.instance.likeComment(
      widget.postId,
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
    setState(() {
      _replyingToId = comment.id;
      _replyingToName = comment.authorName;
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Commentaires',
                  style: AppTextStyles.headline3.copyWith(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_comments.length})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48, color: AppColors.textLight),
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
                            horizontal: 16, vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) => _buildCommentTile(
                          _comments[i],
                          isReply: false,
                        ),
                      ),
          ),

          // Reply indicator
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
                    onTap: () => setState(() {
                      _replyingToId = null;
                      _replyingToName = null;
                    }),
                    child: const Icon(Icons.close, size: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ),

          // Input field
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
                      hintText: _replyingToName != null
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
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
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
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    // Name + time
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
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 10),
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
                                color: comment.isLiked
                                    ? AppColors.primary
                                    : AppColors.textLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesCount}',
                                style: AppTextStyles.caption.copyWith(
                                  color: comment.isLiked
                                      ? AppColors.primary
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isReply) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _setReplyTarget(comment),
                            child: Text(
                              'Répondre',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
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
          // Replies
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
