const Post = require("../models/Post");
const User = require("../../users/models/User");
const {
  canViewerSeeAuthorGlobalContent,
  filterGlobalPostsForViewer,
  countVisibleGlobalPosts,
} = require("../../../utils/privacy");
const notificationsService = require("../../notifications/services/notifications.service");

/**
 * @desc    Get paginated feed of posts (global or community)
 * @route   GET /api/posts
 * @access  Private (auth required)
 */
exports.getFeed = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = {};
    if (req.query.communityId) {
      query.communityId = req.query.communityId;
    } else {
      query.communityId = null;
    }

    const posts = await Post.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate("author", "firstName lastName username avatarUrl")
      .populate("communityId", "name imageUrl");

    posts.forEach((post) => {
      post._currentUser = req.user;
    });

    let data = posts;
    let total;
    if (!req.query.communityId) {
      data = await filterGlobalPostsForViewer(posts, req.user._id);
      total = await countVisibleGlobalPosts(req.user._id);
    } else {
      total = await Post.countDocuments(query);
    }

    res.json({
      success: true,
      data,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get subscription feed (posts from followed users only)
 * @route   GET /api/posts/subscriptions
 * @access  Private
 */
exports.getSubscriptionFeed = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const currentUser = await User.findById(req.user._id).select("following");
    const followingIds = currentUser.following || [];

    if (followingIds.length === 0) {
      return res.json({
        success: true,
        data: [],
        pagination: { page, limit, total: 0, pages: 0 },
      });
    }

    const query = { author: { $in: followingIds }, communityId: null };

    const posts = await Post.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate("author", "firstName lastName username avatarUrl")
      .populate("communityId", "name imageUrl");

    posts.forEach((post) => {
      post._currentUser = req.user;
    });

    const total = await Post.countDocuments(query);

    res.json({
      success: true,
      data: posts,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create a new post
 * @route   POST /api/posts
 * @access  Private (auth required)
 */
exports.createPost = async (req, res, next) => {
  try {
    const { content, communityId } = req.body;
    let imageUrl = "";

    if (req.file) {
      imageUrl = `/uploads/posts/${req.file.filename}`;
    }

    const newPost = await Post.create({
      author: req.user._id,
      content,
      image: imageUrl,
      communityId: communityId || null,
    });

    const populatedPost = await Post.findById(newPost._id).populate(
      "author",
      "firstName lastName username avatarUrl"
    );

    res.status(201).json({
      success: true,
      data: populatedPost,
      message: "Post publié avec succès",
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Toggle Like on a post
 * @route   POST /api/posts/:id/like
 * @access  Private
 */
exports.toggleLike = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id).populate("author");
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    if (!post.communityId && !canViewerSeeAuthorGlobalContent(req.user._id, post.author)) {
      return res.status(403).json({
        success: false,
        message: "Publication non accessible (profil privé)",
      });
    }

    const userId = req.user._id;
    const isLiked = post.likedBy.includes(userId);

    if (isLiked) {
      post.likedBy.pull(userId);
      post.likesCount = Math.max(0, post.likesCount - 1);
    } else {
      post.likedBy.push(userId);
      post.likesCount += 1;
    }

    await post.save();

    // Trigger notification if liked
    if (!isLiked && post.author._id.toString() !== userId.toString()) {
      await notificationsService.createNotification({
        recipient: post.author._id,
        sender: userId,
        type: "like",
        post: post._id,
        text: `${req.user.username} a aimé votre publication`,
      });
    }

    res.json({
      success: true,
      message: isLiked ? "Post unliked" : "Post liked",
      data: { likesCount: post.likesCount, isLiked: !isLiked },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get comments for a post
 * @route   GET /api/posts/:id/comments
 * @access  Private
 */
exports.getComments = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate("author")
      .populate("comments.author", "firstName lastName username avatarUrl")
      .populate("comments.replies.author", "firstName lastName username avatarUrl");

    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    if (!post.communityId && !canViewerSeeAuthorGlobalContent(req.user._id, post.author)) {
      return res.status(403).json({
        success: false,
        message: "Publication non accessible (profil privé)",
      });
    }

    // Filter hidden comments
    // Post owner can see all comments
    // Comment author can see their own hidden comment
    const isPostOwner = post.author._id.toString() === req.user._id.toString();
    
    let filteredComments = post.comments.filter(c => {
      if (!c.isHidden) return true;
      if (isPostOwner) return true;
      if (c.author && c.author._id.toString() === req.user._id.toString()) return true;
      return false;
    });

    // Filter replies and map to include isLiked/likesCount
    const userId = req.user._id.toString();
    
    const processedComments = filteredComments.map(c => {
      const cObj = c.toObject();
      
      // Filter replies
      const filteredReplies = c.replies.filter(r => {
        if (!r.isHidden) return true;
        if (isPostOwner) return true;
        if (r.author && r.author._id.toString() === req.user._id.toString()) return true;
        return false;
      });

      cObj.isLiked = c.likes.some(id => id.toString() === userId);
      cObj.likesCount = c.likes.length;
      
      cObj.replies = filteredReplies.map(r => {
        const rObj = r.toObject ? r.toObject() : r;
        rObj.isLiked = r.likes.some(id => id.toString() === userId);
        rObj.likesCount = r.likes.length;
        return rObj;
      });
      
      return cObj;
    });

    // Sort: Pinned first, then by date desc
    processedComments.sort((a, b) => {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt - a.createdAt;
    });

    res.json({ success: true, data: processedComments });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Add a comment to a post
 * @route   POST /api/posts/:id/comments
 * @access  Private
 */
exports.addComment = async (req, res, next) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, message: "Le contenu est requis" });
    }

    const post = await Post.findById(req.params.id).populate("author");
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    if (!post.communityId && !canViewerSeeAuthorGlobalContent(req.user._id, post.author)) {
      return res.status(403).json({
        success: false,
        message: "Publication non accessible (profil privé)",
      });
    }

    if (post.commentsDisabled) {
      return res.status(403).json({
        success: false,
        message: "Les commentaires sont désactivés pour cette publication",
      });
    }

    post.comments.push({
      author: req.user._id,
      content: content.trim(),
    });
    post.commentsCount = post.comments.length;
    await post.save();

    // Trigger notification
    if (post.author._id.toString() !== req.user._id.toString()) {
      await notificationsService.createNotification({
        recipient: post.author._id,
        sender: req.user._id,
        type: "comment",
        post: post._id,
        text: `${req.user.username} a commenté votre publication`,
      });
    }

    // Re-fetch to populate
    const updated = await Post.findById(post._id)
      .populate("comments.author", "firstName lastName username avatarUrl");

    const newComment = updated.comments[updated.comments.length - 1].toObject();
    newComment.isLiked = false;
    newComment.likesCount = 0;

    res.status(201).json({
      success: true,
      data: newComment,
      message: "Commentaire ajouté",
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Reply to a comment
 * @route   POST /api/posts/:id/comments/:commentId/reply
 * @access  Private
 */
exports.replyToComment = async (req, res, next) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, message: "Le contenu est requis" });
    }

    const post = await Post.findById(req.params.id).populate("author");
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    if (!post.communityId && !canViewerSeeAuthorGlobalContent(req.user._id, post.author)) {
      return res.status(403).json({
        success: false,
        message: "Publication non accessible (profil privé)",
      });
    }

    const comment = post.comments.id(req.params.commentId);
    if (!comment) {
      return res.status(404).json({ success: false, message: "Commentaire introuvable" });
    }

    comment.replies.push({
      author: req.user._id,
      content: content.trim(),
    });
    await post.save();

    // Trigger notification for the comment author
    if (comment.author.toString() !== req.user._id.toString()) {
      await notificationsService.createNotification({
        recipient: comment.author,
        sender: req.user._id,
        type: "reply",
        post: post._id,
        comment: comment._id,
        text: `${req.user.username} a répondu à votre commentaire`,
      });
    }

    const updated = await Post.findById(post._id)
      .populate("comments.replies.author", "firstName lastName username avatarUrl");

    const updatedComment = updated.comments.id(req.params.commentId);
    const newReply = updatedComment.replies[updatedComment.replies.length - 1].toObject();
    newReply.isLiked = false;
    newReply.likesCount = 0;

    res.status(201).json({
      success: true,
      data: newReply,
      message: "Réponse ajoutée",
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Like/unlike a comment
 * @route   POST /api/posts/:id/comments/:commentId/like
 * @access  Private
 */
exports.likeComment = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id).populate("author");
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    if (!post.communityId && !canViewerSeeAuthorGlobalContent(req.user._id, post.author)) {
      return res.status(403).json({
        success: false,
        message: "Publication non accessible (profil privé)",
      });
    }

    let comment = post.comments.id(req.params.commentId);
    
    // Search in replies if not found in top-level comments
    if (!comment) {
      for (const c of post.comments) {
        const reply = c.replies.id(req.params.commentId);
        if (reply) {
          comment = reply;
          break;
        }
      }
    }

    if (!comment) {
      return res.status(404).json({ success: false, message: "Commentaire introuvable" });
    }

    const userId = req.user._id;
    const isLiked = comment.likes.includes(userId);

    if (isLiked) {
      comment.likes.pull(userId);
    } else {
      comment.likes.push(userId);
    }

    await post.save();

    res.json({
      success: true,
      data: { likesCount: comment.likes.length, isLiked: !isLiked },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Share a post (increment share count)
 * @route   POST /api/posts/:id/share
 * @access  Private
 */
exports.sharePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id).populate("author");
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    if (!post.communityId && !canViewerSeeAuthorGlobalContent(req.user._id, post.author)) {
      return res.status(403).json({
        success: false,
        message: "Publication non accessible (profil privé)",
      });
    }

    post.sharesCount += 1;
    await post.save();

    res.json({
      success: true,
      data: { sharesCount: post.sharesCount },
      message: "Post partagé",
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Toggle follow/unfollow a user
 * @route   POST /api/users/:id/follow
 * @access  Private
 */
exports.toggleFollow = async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const currentUserId = req.user._id;

    if (targetUserId === currentUserId.toString()) {
      return res.status(400).json({ success: false, message: "Vous ne pouvez pas vous suivre vous-même" });
    }

    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({ success: false, message: "Utilisateur introuvable" });
    }

    const currentUser = await User.findById(currentUserId);
    const isFollowing = currentUser.following.some((id) => id.toString() === targetUserId);

    // Déjà abonné → se désabonner
    if (isFollowing) {
      currentUser.following.pull(targetUserId);
      targetUser.followers.pull(currentUserId);
      targetUser.pendingFollowRequests.pull(currentUserId);
      await currentUser.save();
      await targetUser.save();
      return res.json({
        success: true,
        data: {
          isFollowing: false,
          followRequestSent: false,
          followersCount: targetUser.followers.length,
          followingCount: currentUser.following.length,
          userId: targetUserId,
        },
        message: "Désabonné",
      });
    }

    const isPrivate = targetUser.accountPrivacy === "private";
    const pending = (targetUser.pendingFollowRequests || []).some(
      (id) => id.toString() === currentUserId.toString()
    );

    if (isPrivate) {
      if (pending) {
        // Annuler la demande
        targetUser.pendingFollowRequests.pull(currentUserId);
        await targetUser.save();
        return res.json({
          success: true,
          data: {
            isFollowing: false,
            followRequestSent: false,
            followersCount: targetUser.followers.length,
            followingCount: currentUser.following.length,
            userId: targetUserId,
          },
          message: "Demande annulée",
        });
      }
      targetUser.pendingFollowRequests.push(currentUserId);
      await targetUser.save();

      // Trigger notification for follow request
      await notificationsService.createNotification({
        recipient: targetUserId,
        sender: currentUserId,
        type: "follow",
        text: `${req.user.username} souhaite vous suivre`,
      });

      return res.json({
        success: true,
        data: {
          isFollowing: false,
          followRequestSent: true,
          followersCount: targetUser.followers.length,
          followingCount: currentUser.following.length,
          userId: targetUserId,
        },
        message: "Demande d'abonnement envoyée",
      });
    }

    // Compte public : abonnement immédiat
    currentUser.following.push(targetUserId);
    targetUser.followers.push(currentUserId);
    await currentUser.save();
    await targetUser.save();

    // Trigger notification
    await notificationsService.createNotification({
      recipient: targetUserId,
      sender: currentUserId,
      type: "follow",
      text: `${req.user.username} a commencé à vous suivre`,
    });

    res.json({
      success: true,
      data: {
        isFollowing: true,
        followRequestSent: false,
        followersCount: targetUser.followers.length,
        followingCount: currentUser.following.length,
        userId: targetUserId,
      },
      message: "Abonné",
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update a comment
 * @route   PUT /api/posts/:id/comments/:commentId
 */
exports.updateComment = async (req, res, next) => {
  try {
    const { content } = req.body;
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: "Post introuvable" });

    let comment = post.comments.id(req.params.commentId);
    
    // Search in replies if not found in top-level comments
    if (!comment) {
      for (const c of post.comments) {
        const reply = c.replies.id(req.params.commentId);
        if (reply) {
          comment = reply;
          break;
        }
      }
    }

    if (!comment) return res.status(404).json({ success: false, message: "Commentaire introuvable" });

    if (comment.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: "Action non autorisée" });
    }

    comment.content = content;
    await post.save();
    res.json({ success: true, message: "Commentaire modifié", data: comment });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete a comment
 * @route   DELETE /api/posts/:id/comments/:commentId
 */
exports.deleteComment = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: "Post introuvable" });

    let comment = post.comments.id(req.params.commentId);
    let parentComment = null;

    if (!comment) {
      for (const c of post.comments) {
        const reply = c.replies.id(req.params.commentId);
        if (reply) {
          comment = reply;
          parentComment = c;
          break;
        }
      }
    }

    if (!comment) return res.status(404).json({ success: false, message: "Commentaire introuvable" });

    const isPostOwner = post.author.toString() === req.user._id.toString();
    const isCommentAuthor = comment.author.toString() === req.user._id.toString();

    if (!isPostOwner && !isCommentAuthor) {
      return res.status(403).json({ success: false, message: "Action non autorisée" });
    }

    if (parentComment) {
      parentComment.replies.pull(req.params.commentId);
    } else {
      post.comments.pull(req.params.commentId);
    }
    
    post.commentsCount = post.comments.length + post.comments.reduce((acc, c) => acc + c.replies.length, 0);
    await post.save();
    res.json({ success: true, message: "Commentaire supprimé" });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Toggle hide/unhide a comment
 * @route   POST /api/posts/:id/comments/:commentId/hide
 */
exports.toggleHideComment = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: "Post introuvable" });

    let comment = post.comments.id(req.params.commentId);
    
    if (!comment) {
      for (const c of post.comments) {
        const reply = c.replies.id(req.params.commentId);
        if (reply) {
          comment = reply;
          break;
        }
      }
    }

    if (!comment) return res.status(404).json({ success: false, message: "Commentaire introuvable" });

    const isPostOwner = post.author.toString() === req.user._id.toString();
    const isCommentAuthor = comment.author.toString() === req.user._id.toString();

    if (!isPostOwner && !isCommentAuthor) {
      return res.status(403).json({ success: false, message: "Action non autorisée" });
    }

    comment.isHidden = !comment.isHidden;
    await post.save();
    res.json({ success: true, message: comment.isHidden ? "Commentaire masqué" : "Commentaire affiché", data: { isHidden: comment.isHidden } });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Toggle pin/unpin a comment
 * @route   POST /api/posts/:id/comments/:commentId/pin
 */
exports.togglePinComment = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: "Post introuvable" });

    if (post.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: "Action réservée au propriétaire de la publication" });
    }

    const comment = post.comments.id(req.params.commentId);
    if (!comment) return res.status(404).json({ success: false, message: "Commentaire introuvable" });

    const wasPinned = comment.isPinned;
    
    // Unpin others if we are pinning this one
    if (!wasPinned) {
      post.comments.forEach(c => c.isPinned = false);
    }
    
    comment.isPinned = !wasPinned;
    await post.save();
    res.json({ success: true, message: comment.isPinned ? "Commentaire épinglé" : "Commentaire désépinglé", data: { isPinned: comment.isPinned } });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Toggle disable/enable comments for a post
 * @route   POST /api/posts/:id/toggle-comments
 */
exports.toggleCommentsDisabled = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: "Post introuvable" });

    if (post.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: "Action non autorisée" });
    }

    post.commentsDisabled = !post.commentsDisabled;
    await post.save();
    res.json({ success: true, message: post.commentsDisabled ? "Commentaires désactivés" : "Commentaires activés", data: { commentsDisabled: post.commentsDisabled } });
  } catch (error) {
    next(error);
  }
};
