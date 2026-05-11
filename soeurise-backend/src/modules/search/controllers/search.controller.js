const usersService = require("../../users/services/users.service");
const Post = require("../../posts/models/Post");
const Group = require("../../community/models/Group");
const { filterGlobalPostsForViewer } = require("../../../utils/privacy");

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function searchAll(req, res, next) {
  try {
    const q = (req.query.q || "").toString().trim();
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : 10;

    if (!q || q.length < 2) {
      return res.json({
        success: true,
        data: { users: [], posts: [], hashtags: [], groups: [] },
      });
    }

    const safeLimit = Number.isFinite(limit) && limit > 0 ? limit : 10;
    const escaped = escapeRegex(q);
    const regex = new RegExp(escaped, "i");

    const tag = q.startsWith("#") ? q.slice(1) : q;
    const tagLower = tag.toLowerCase();
    const tagRegex = new RegExp(`^${escapeRegex(tagLower)}`, "i");

    const [users, groups, postsRaw, hashtags] = await Promise.all([
      usersService.searchUsers(q, safeLimit),
      Group.find({
        isPublic: true,
        $or: [{ name: regex }, { description: regex }],
      })
        .sort({ createdAt: -1 })
        .limit(safeLimit),
      Post.find({
        communityId: null,
        $or: [
          { content: regex },
          { hashtags: tagLower },
          { content: new RegExp(`#${escaped}`, "i") },
        ],
      })
        .sort({ createdAt: -1 })
        .limit(safeLimit)
        .populate("author", "firstName lastName username avatarUrl")
        .populate("communityId", "name imageUrl"),
      Post.aggregate([
        { $match: { communityId: null, hashtags: { $exists: true, $ne: [] } } },
        { $unwind: "$hashtags" },
        { $match: { hashtags: tagRegex } },
        { $group: { _id: "$hashtags", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
    ]);

    postsRaw.forEach((p) => {
      p._currentUser = req.user;
    });
    const posts = await filterGlobalPostsForViewer(postsRaw, req.user._id);

    res.json({
      success: true,
      data: {
        users,
        posts,
        groups: groups.map((g) => g.toPublic()),
        hashtags: hashtags.map((h) => ({ tag: h._id, count: h.count })),
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { searchAll };
