const usersService = require("../services/users.service");
const { updateProfileSchema } = require("../validators/users.validators");
const User = require("../models/User");

/**
 * GET /api/users/me
 */
async function getMe(req, res, next) {
    try {
        res.json({ success: true, data: { user: req.user.toPublic() } });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/users/:id
 * Get a public user profile with follow status
 */
async function getUserById(req, res, next) {
    try {
        const targetUser = await User.findById(req.params.id);
        if (!targetUser || !targetUser.isActive) {
            return res.status(404).json({
                success: false,
                message: "Utilisateur non trouvé",
            });
        }

        const viewer = req.user;
        const isSelf = viewer && viewer._id.toString() === targetUser._id.toString();

        // Check for blocks
        const viewerBlockedByTarget = viewer && targetUser.blockedUsers.some(id => id.toString() === viewer._id.toString());
        const targetBlockedByViewer = viewer && viewer.blockedUsers.some(id => id.toString() === targetUser._id.toString());

        if (viewerBlockedByTarget && !isSelf) {
            return res.status(404).json({
                success: false,
                message: "Utilisateur non trouvé",
            });
        }

        const isFollowing = viewer ? viewer.following.some((id) => id.toString() === targetUser._id.toString()) : false;
        const followRequestSent = viewer
            ? (targetUser.pendingFollowRequests || []).some((id) => id.toString() === viewer._id.toString())
            : false;

        const isPrivate = targetUser.accountPrivacy === "private";
        const limited = isPrivate && !isSelf && !isFollowing;

        if (limited) {
            const p = targetUser.toPublic();
            res.json({
                success: true,
                data: {
                    user: {
                        id: p.id,
                        username: p.username,
                        avatarUrl: p.avatarUrl,
                        accountPrivacy: p.accountPrivacy,
                        followersCount: p.followersCount,
                        followingCount: p.followingCount,
                        role: p.role,
                        isActive: p.isActive,
                        createdAt: p.createdAt,
                        firstName: "",
                        lastName: "",
                        email: "",
                        isFollowing: false,
                        isBlocked: targetBlockedByViewer,
                        followRequestSent,
                        canViewContent: false,
                    },
                },
            });
            return;
        }

        const publicData = targetUser.toPublic();

        res.json({
            success: true,
            data: {
                user: {
                    ...publicData,
                    isFollowing,
                    followRequestSent: isFollowing ? false : followRequestSent,
                    isBlocked: targetBlockedByViewer,
                    canViewContent: true,
                },
            },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * PUT /api/users/me
 */
async function updateMe(req, res, next) {
    try {
        const { error, value } = updateProfileSchema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true, // supprime role, isActive, etc.
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const user = await usersService.updateProfile(req.user._id, value);
        res.json({
            success: true,
            message: "Profil mis à jour",
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * PUT /api/users/me/avatar
 */
async function updateAvatar(req, res, next) {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: "Aucun fichier avatar envoyé",
            });
        }

        const user = await usersService.updateAvatar(req.user._id, req.file);
        res.json({
            success: true,
            message: "Avatar mis à jour",
            data: { user },
        });
    } catch (err) {
        console.error('Error updating avatar:', err);
        next(err);
    }
}

/**
 * DELETE /api/users/me/avatar
 */
async function deleteAvatar(req, res, next) {
    try {
        const user = await usersService.deleteAvatar(req.user._id);
        res.json({
            success: true,
            message: "Avatar supprimé",
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/users/me/follow-requests
 */
async function getMyFollowRequests(req, res, next) {
    try {
        const users = await usersService.listIncomingFollowRequests(req.user._id);
        res.json({
            success: true,
            data: { requests: users },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/users/me/follow-requests/:userId/accept
 */
async function acceptFollowRequest(req, res, next) {
    try {
        await usersService.acceptFollowRequest(req.user._id, req.params.userId);
        res.json({ success: true, message: "Demande acceptée" });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/users/me/follow-requests/:userId/decline
 */
async function declineFollowRequest(req, res, next) {
    try {
        await usersService.declineFollowRequest(req.user._id, req.params.userId);
        res.json({ success: true, message: "Demande refusée" });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/users/me/followers
 * Get list of followers for current user
 */
async function getMyFollowers(req, res, next) {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const user = await User.findById(req.user._id)
            .populate({
                path: "followers",
                select: "id firstName lastName username avatarUrl accountPrivacy",
                skip,
                limit,
            });

        if (!user) {
            return res.status(404).json({ success: false, message: "Utilisateur non trouvé" });
        }

        const followers = (user.followers || []).map((f) => ({
            id: f._id,
            firstName: f.firstName,
            lastName: f.lastName,
            username: f.username,
            email: "",
            avatarUrl: f.avatarUrl,
            role: "user",
            isActive: true,
            followingCount: 0,
            followersCount: 0,
            isFollowing: false,
            accountPrivacy: f.accountPrivacy || "public",
            followRequestSent: false,
            canViewContent: true,
        }));

        res.json({
            success: true,
            followers,
            total: user.followers?.length || 0,
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/users/:userId/followers
 * Get list of followers for a specific user (public profile)
 */
async function getUserFollowers(req, res, next) {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const targetUser = await User.findById(req.params.userId)
            .populate({
                path: "followers",
                select: "id firstName lastName username avatarUrl accountPrivacy",
                skip,
                limit,
            });

        if (!targetUser || !targetUser.isActive) {
            return res.status(404).json({ success: false, message: "Utilisateur non trouvé" });
        }

        // Check if profile is private and if viewer is allowed to see followers
        const viewer = req.user;
        const isSelf = viewer && viewer._id.toString() === targetUser._id.toString();
        const isFollowing = viewer ? viewer.following.some((id) => id.toString() === targetUser._id.toString()) : false;
        const isPrivate = targetUser.accountPrivacy === "private";

        // Only self, followers, or public profiles can see followers list
        if (isPrivate && !isSelf && !isFollowing) {
            return res.status(403).json({
                success: false,
                message: "Ce compte est privé. Les followers de ce compte ne sont pas visibles.",
            });
        }

        const followers = (targetUser.followers || []).map((f) => ({
            id: f._id,
            firstName: f.firstName,
            lastName: f.lastName,
            username: f.username,
            email: "",
            avatarUrl: f.avatarUrl,
            role: "user",
            isActive: true,
            followingCount: 0,
            followersCount: 0,
            isFollowing: false,
            accountPrivacy: f.accountPrivacy || "public",
            followRequestSent: false,
            canViewContent: true,
        }));

        res.json({
            success: true,
            followers,
            total: targetUser.followers?.length || 0,
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/users/:id/block
 */
async function blockUser(req, res, next) {
    try {
        const result = await usersService.blockUser(req.user._id, req.params.id);
        res.json({ success: true, ...result });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/users/:id/unblock
 */
async function unblockUser(req, res, next) {
    try {
        const result = await usersService.unblockUser(req.user._id, req.params.id);
        res.json({ success: true, ...result });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/users/search?q=...
 */
async function searchUsers(req, res, next) {
    try {
        const query = req.query.q;
        const users = await usersService.searchUsers(query);
        res.json({ success: true, data: { users } });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/users/me/blocked
 */
async function getBlockedUsers(req, res, next) {
    try {
        const users = await usersService.listBlockedUsers(req.user._id);
        res.json({ success: true, data: { users } });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    getMe,
    getUserById,
    updateMe,
    updateAvatar,
    deleteAvatar,
    getMyFollowRequests,
    acceptFollowRequest,
    declineFollowRequest,
    getMyFollowers,
    getUserFollowers,
    blockUser,
    unblockUser,
    searchUsers,
    getBlockedUsers,
};
