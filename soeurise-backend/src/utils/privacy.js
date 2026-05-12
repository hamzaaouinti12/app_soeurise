const mongoose = require("mongoose");

const User = require("../modules/users/models/User");
const Post = require("../modules/posts/models/Post");

/**
 * Peut voir le contenu (posts hors communautés) publiés par cet auteur.
 * @param {import("mongoose").Types.ObjectId|string|null} viewerId
 * @param {{ _id?: any; accountPrivacy?: string; followers?: any[] }} authorDoc Document User minimal (followers peuplés ou ids)
 */
function canViewerSeeAuthorGlobalContent(viewerId, authorDoc) {
  if (!authorDoc || !authorDoc._id) return false;
  if (!viewerId || !mongoose.Types.ObjectId.isValid(viewerId)) return false;

  const v = viewerId.toString();
  const aId = authorDoc._id.toString();
  if (v === aId) return true;

  // Check if blocked (either way)
  const blockedByAuthor = (authorDoc.blockedUsers || []).some((id) => id.toString() === v);
  if (blockedByAuthor) return false;

  // Note: We don't necessarily have viewerDoc here, so we assume if we reach here, 
  // the viewer hasn't blocked the author or it will be filtered at the query level.

  const privacy = authorDoc.accountPrivacy || "public";
  if (privacy !== "private") return true;

  const followers = authorDoc.followers || [];
  return followers.some((f) => f.toString() === v);
}

/**
 * Filtre les posts globaux (sans communauté) selon confidentialité :
 * posts publics, ou auteur que le viewer suit, ou ses propres posts.
 * Posts en communauté ne sont pas filtrés (visibilité = adhésion au groupe).
 * @param {any[]} posts
 * @param {import("mongoose").Types.ObjectId} viewerId
 */
async function filterGlobalPostsForViewer(posts, viewerId) {
  if (!posts.length) return posts;

  const vid = viewerId.toString();

  // Get viewer's blocked users
  const viewer = await User.findById(viewerId).select("blockedUsers").lean();
  const viewerBlocked = (viewer?.blockedUsers || []).map((id) => id.toString());

  const authorIdsNeeded = [];
  for (const p of posts) {
    if (!p.communityId && p.author && p.author._id) {
      const aid = p.author._id.toString();
      if (aid !== vid) authorIdsNeeded.push(p.author._id);
    }
  }

  const uniqueAuthorIds = [...new Set(authorIdsNeeded.map((id) => id.toString()))].map(
    (id) => new mongoose.Types.ObjectId(id)
  );

  if (!uniqueAuthorIds.length) {
      // Still need to filter out authors who blocked the viewer, even if no private accounts
      const allAuthors = await User.find({ _id: { $in: uniqueAuthorIds } }).select("blockedUsers").lean();
      const blockerMap = new Map(allAuthors.map(u => [u._id.toString(), u.blockedUsers || []]));
      return posts.filter(p => {
          if (p.communityId) return true;
          if (!p.author || !p.author._id) return false;
          const aid = p.author._id.toString();
          if (aid === vid) return true;
          if (viewerBlocked.includes(aid)) return false;
          const blockedMe = (blockerMap.get(aid) || []).some(id => id.toString() === vid);
          return !blockedMe;
      });
  }

  const authorsData = await User.find({
    _id: { $in: uniqueAuthorIds }
  })
    .select("followers accountPrivacy blockedUsers")
    .lean();

  /** @type {Map<string, any>} */
  const authorMap = new Map(authorsData.map((d) => [d._id.toString(), d]));

  return posts.filter((p) => {
    if (p.communityId) return true;
    if (!p.author || !p.author._id) return false;
    const aid = p.author._id.toString();
    if (aid === vid) return true;

    // Check if viewer blocked author
    if (viewerBlocked.includes(aid)) return false;

    const author = authorMap.get(aid);
    if (!author) return true; 

    // Check if author blocked viewer
    const blockedMe = (author.blockedUsers || []).some(id => id.toString() === vid);
    if (blockedMe) return false;

    // Check privacy
    if (author.accountPrivacy === "private") {
        const followers = author.followers || [];
        return followers.some((f) => f.toString() === vid);
    }

    return true;
  });
}

/**
 * Compte posts globaux visibles pour le viewer (communityId null).
 */
async function countVisibleGlobalPosts(viewerId) {
  const oid = new mongoose.Types.ObjectId(viewerId);
  
  // Get viewer's blocked users to exclude them from the count
  const viewer = await User.findById(viewerId).select("blockedUsers").lean();
  const viewerBlocked = (viewer?.blockedUsers || []).map((id) => new mongoose.Types.ObjectId(id));

  const results = await Post.aggregate([
    { $match: { communityId: null, author: { $nin: viewerBlocked } } },
    {
      $lookup: {
        from: "users",
        localField: "author",
        foreignField: "_id",
        as: "authorDoc",
      },
    },
    { $unwind: "$authorDoc" },
    {
      $match: {
        $and: [
          { "authorDoc.blockedUsers": { $ne: oid } }, // Author didn't block viewer
          {
            $or: [
              { author: oid },
              { "authorDoc.accountPrivacy": { $ne: "private" } },
              { "authorDoc.followers": oid },
            ],
          }
        ]
      },
    },
    { $count: "c" },
  ]);
  return results[0]?.c ?? 0;
}

module.exports = {
  canViewerSeeAuthorGlobalContent,
  filterGlobalPostsForViewer,
  countVisibleGlobalPosts,
};
