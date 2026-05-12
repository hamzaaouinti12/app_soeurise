const Story = require("../models/Story");
const User = require("../../users/models/User");
const { canViewerSeeAuthorGlobalContent } = require("../../../utils/privacy");

const allowedReactions = ["❤️", "🔥", "👍", "👏", "😮"];

function mapStoryWithViewFlag(story, viewerId) {
  const data = story.toObject({ virtuals: true });
  data.isViewed = Array.isArray(story.views)
    ? story.views.some((view) => view.user.toString() === viewerId)
    : false;
  return data;
}

exports.getActiveStories = async (req, res, next) => {
  try {
    const currentUser = await User.findById(req.user._id).select("following");
    const authorIds = [req.user._id];
    if (Array.isArray(currentUser?.following)) {
      authorIds.push(...currentUser.following);
    }

    const stories = await Story.find({
      author: { $in: authorIds },
      expiresAt: { $gt: new Date() },
    })
      .sort({ createdAt: -1 })
      .populate("author", "firstName lastName username avatarUrl");

    const data = stories.map((story) =>
      mapStoryWithViewFlag(story, req.user._id.toString())
    );

    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

exports.getUserStories = async (req, res, next) => {
  try {
    const userId = req.params.userId;
    const user = await User.findById(userId).select("accountPrivacy followers");
    if (!user) {
      return res.status(404).json({ success: false, message: "Utilisateur introuvable" });
    }

    const isSelf = req.user._id.toString() === user._id.toString();
    const isFollower = Array.isArray(user.followers)
      ? user.followers.some((id) => id.toString() === req.user._id.toString())
      : false;

    if (!isSelf && user.accountPrivacy === "private" && !isFollower) {
      return res.status(403).json({
        success: false,
        message: "Stories privées, vous ne pouvez pas les voir",
      });
    }

    const stories = await Story.find({
      author: user._id,
      expiresAt: { $gt: new Date() },
    })
      .sort({ createdAt: -1 })
      .populate("author", "firstName lastName username avatarUrl");

    const data = stories.map((story) =>
      mapStoryWithViewFlag(story, req.user._id.toString())
    );

    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

exports.getStoryViews = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id).populate(
      "views.user",
      "firstName lastName username avatarUrl"
    );
    if (!story) {
      return res.status(404).json({ success: false, message: "Story introuvable" });
    }

    const isAuthor = story.author.toString() === req.user._id.toString();
    if (!isAuthor) {
      return res.status(403).json({ success: false, message: "Accès interdit" });
    }

    const viewers = (story.views || [])
      .map((view) => ({
        user: view.user,
        viewedAt: view.viewedAt,
      }))
      .sort((a, b) => {
        const aTime = a.viewedAt ? a.viewedAt.getTime() : 0;
        const bTime = b.viewedAt ? b.viewedAt.getTime() : 0;
        return bTime - aTime;
      });

    res.json({ success: true, data: { viewers } });
  } catch (error) {
    next(error);
  }
};

exports.createStory = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Un fichier image ou vidéo est requis pour créer une story",
      });
    }

    const mime = req.file.mimetype || "";
    const mediaType = mime.startsWith("video/") ? "video" : "image";
    const mediaUrl = `/uploads/stories/${req.file.filename}`;
    const caption = req.body.caption?.toString().trim() || "";
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const story = await Story.create({
      author: req.user._id,
      mediaUrl,
      mediaType,
      caption,
      expiresAt,
    });

    const populatedStory = await Story.findById(story._id).populate(
      "author",
      "firstName lastName username avatarUrl"
    );

    res.status(201).json({ success: true, data: populatedStory, message: "Story publiée" });
  } catch (error) {
    next(error);
  }
};

exports.addView = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id);
    if (!story) {
      return res.status(404).json({ success: false, message: "Story introuvable" });
    }

    const userId = req.user._id.toString();
    const alreadyViewed = story.views.some((view) => view.user.toString() === userId);
    if (!alreadyViewed) {
      story.views.push({ user: req.user._id });
      await story.save();
    }

    res.json({ success: true, data: { viewsCount: story.views.length } });
  } catch (error) {
    next(error);
  }
};

exports.reactToStory = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id);
    if (!story) {
      return res.status(404).json({ success: false, message: "Story introuvable" });
    }

    // L'auteur ne peut pas réagir à sa propre story
    if (story.author.toString() === req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Vous ne pouvez pas réagir à votre propre story",
      });
    }

    const reaction = req.body.type?.toString();
    if (!reaction || !allowedReactions.includes(reaction)) {
      return res.status(400).json({
        success: false,
        message: "Type de réaction invalide",
      });
    }

    const userId = req.user._id.toString();
    const existing = story.reactions.find((item) => item.user.toString() === userId);
    if (existing) {
      existing.type = reaction;
      existing.reactedAt = new Date();
    } else {
      story.reactions.push({ user: req.user._id, type: reaction });
    }

    await story.save();

    const reactionCounts = story.reactions.reduce((counts, item) => {
      counts[item.type] = (counts[item.type] || 0) + 1;
      return counts;
    }, {});

    res.json({ success: true, data: { reactionCounts } });
  } catch (error) {
    next(error);
  }
};

exports.deleteStory = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id);
    if (!story) {
      return res.status(404).json({ success: false, message: "Story introuvable" });
    }

    // Vérifier que l'utilisateur est l'auteur de la story
    if (story.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: "Vous ne pouvez supprimer que vos propres stories" });
    }

    // Supprimer la story
    await Story.findByIdAndDelete(req.params.id);

    res.json({ success: true, message: "Story supprimée avec succès" });
  } catch (error) {
    next(error);
  }
};
