const Post = require("../models/Post");
const User = require("../../users/models/User");

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
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
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
      .populate("comments.author", "firstName lastName username avatarUrl")
      .populate("comments.replies.author", "firstName lastName username avatarUrl");

    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    const comments = post.comments.sort((a, b) => b.createdAt - a.createdAt);

    res.json({ success: true, data: comments });
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

    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    post.comments.push({
      author: req.user._id,
      content: content.trim(),
    });
    post.commentsCount = post.comments.length;
    await post.save();

    // Re-fetch to populate
    const updated = await Post.findById(post._id)
      .populate("comments.author", "firstName lastName username avatarUrl");

    const newComment = updated.comments[updated.comments.length - 1];

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

    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
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

    const updated = await Post.findById(post._id)
      .populate("comments.replies.author", "firstName lastName username avatarUrl");

    const updatedComment = updated.comments.id(req.params.commentId);
    const newReply = updatedComment.replies[updatedComment.replies.length - 1];

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
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
    }

    const comment = post.comments.id(req.params.commentId);
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
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post introuvable" });
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
    const isFollowing = currentUser.following.includes(targetUserId);

    if (isFollowing) {
      currentUser.following.pull(targetUserId);
      targetUser.followers.pull(currentUserId);
    } else {
      currentUser.following.push(targetUserId);
      targetUser.followers.push(currentUserId);
    }

    await currentUser.save();
    await targetUser.save();

    res.json({
      success: true,
      data: { isFollowing: !isFollowing },
      message: isFollowing ? "Désabonné" : "Abonné",
    });
  } catch (error) {
    next(error);
  }
};
