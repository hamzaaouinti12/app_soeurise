const Report = require("../models/Report");
const User = require("../../users/models/User");
const Post = require("../../posts/models/Post");
const { canViewerSeeAuthorGlobalContent } = require("../../../utils/privacy");

async function createReport(req, res, next) {
  try {
    const { type, targetId, reason, details } = req.body;

    if (!type || !targetId || !reason) {
      return res.status(400).json({
        success: false,
        message: "type, targetId et reason sont requis",
      });
    }

    if (type !== "user" && type !== "post") {
      return res.status(400).json({
        success: false,
        message: "type invalide (user ou post)",
      });
    }

    let targetUser = null;
    let targetPost = null;

    if (type === "user") {
      targetUser = await User.findById(targetId);
      if (!targetUser) {
        return res.status(404).json({ success: false, message: "Utilisateur introuvable" });
      }
    } else {
      targetPost = await Post.findById(targetId).populate("author");
      if (!targetPost) {
        return res.status(404).json({ success: false, message: "Publication introuvable" });
      }
      if (!targetPost.communityId && !canViewerSeeAuthorGlobalContent(req.user._id, targetPost.author)) {
        return res.status(403).json({ success: false, message: "Publication non accessible" });
      }
    }

    const report = await Report.create({
      reporter: req.user._id,
      targetUser: targetUser ? targetUser._id : null,
      targetPost: targetPost ? targetPost._id : null,
      reason: reason.toString().trim(),
      details: details ? details.toString().trim() : "",
    });

    res.status(201).json({
      success: true,
      message: "Signalement envoye",
      data: { reportId: report._id },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { createReport };
