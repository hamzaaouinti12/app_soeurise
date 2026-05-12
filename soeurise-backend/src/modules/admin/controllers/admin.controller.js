const adminService = require("../services/admin.service");
const Post = require("../../posts/models/Post");
const Event = require("../../events/models/Event");
const Masterclass = require("../../masterclass/models/Masterclass");
const User = require("../../users/models/User");
const {
    listUsersSchema,
    userIdSchema,
    updateRoleSchema,
    updateStatusSchema,
} = require("../validators/admin.validators");

/**
 * GET /api/admin/stats
 * Dashboard statistics
 */
async function getStats(req, res, next) {
    try {
        const [totalUsers, totalPosts, totalEvents, totalMasterclasses] = await Promise.all([
            User.countDocuments(),
            Post.countDocuments(),
            Event.countDocuments(),
            Masterclass.countDocuments(),
        ]);

        // Count total comments across all posts
        const commentAgg = await Post.aggregate([
            { $project: { commentsCount: { $size: "$comments" } } },
            { $group: { _id: null, total: { $sum: "$commentsCount" } } },
        ]);
        const totalComments = commentAgg.length > 0 ? commentAgg[0].total : 0;

        res.json({
            success: true,
            data: {
                totalUsers,
                totalPosts,
                totalEvents,
                totalMasterclasses,
                totalComments,
            },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/admin/users
 * Liste paginée avec recherche
 */
async function listUsers(req, res, next) {
    try {
        const { error, value } = listUsersSchema.validate(req.query);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const { page, limit, search } = value;
        const data = await adminService.listUsers(page, limit, search);

        res.json({ success: true, data });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/admin/users/:id
 * Détail d'un utilisateur
 */
async function getUserById(req, res, next) {
    try {
        const { error } = userIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID invalide",
                errors: error.details.map((d) => d.message),
            });
        }

        const user = await adminService.getUserById(req.params.id);
        res.json({ success: true, data: { user } });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/admin/users/:id/role
 * Modifier le rôle
 */
async function updateRole(req, res, next) {
    try {
        const { error: idError } = userIdSchema.validate(req.params);
        if (idError) {
            return res.status(400).json({
                success: false,
                message: "ID invalide",
                errors: idError.details.map((d) => d.message),
            });
        }

        const { error: bodyError, value } = updateRoleSchema.validate(req.body);
        if (bodyError) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: bodyError.details.map((d) => d.message),
            });
        }

        const user = await adminService.updateUserRole(req.params.id, value.role);
        res.json({
            success: true,
            message: "Rôle mis à jour",
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/admin/users/:id/status
 * Activer/désactiver
 */
async function updateStatus(req, res, next) {
    try {
        const { error: idError } = userIdSchema.validate(req.params);
        if (idError) {
            return res.status(400).json({
                success: false,
                message: "ID invalide",
                errors: idError.details.map((d) => d.message),
            });
        }

        const { error: bodyError, value } = updateStatusSchema.validate(req.body);
        if (bodyError) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: bodyError.details.map((d) => d.message),
            });
        }

        const user = await adminService.updateUserStatus(req.params.id, value.isActive);
        res.json({
            success: true,
            message: user.isActive ? "Utilisateur activé" : "Utilisateur désactivé",
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * DELETE /api/admin/users/:id
 * Supprimer utilisateur + avatar
 */
async function deleteUser(req, res, next) {
    try {
        const { error } = userIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID invalide",
                errors: error.details.map((d) => d.message),
            });
        }

        const result = await adminService.deleteUser(req.params.id, req.user._id);
        res.json({ success: true, message: result.message });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/admin/posts
 * Liste paginée de tous les posts
 */
async function listPosts(req, res, next) {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const posts = await Post.find()
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .populate("author", "firstName lastName username avatarUrl");

        const total = await Post.countDocuments();

        res.json({
            success: true,
            data: {
                posts,
                pagination: { page, limit, total, pages: Math.ceil(total / limit) },
            },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * DELETE /api/admin/posts/:id
 * Supprimer un post
 */
async function deletePost(req, res, next) {
    try {
        const post = await Post.findByIdAndDelete(req.params.id);
        if (!post) {
            return res.status(404).json({ success: false, message: "Post introuvable" });
        }
        res.json({ success: true, message: "Post supprimé" });
    } catch (err) {
        next(err);
    }
}

/**
 * DELETE /api/admin/posts/:postId/comments/:commentId
 * Supprimer un commentaire
 */
async function deleteComment(req, res, next) {
    try {
        const post = await Post.findById(req.params.postId);
        if (!post) {
            return res.status(404).json({ success: false, message: "Post introuvable" });
        }

        const comment = post.comments.id(req.params.commentId);
        if (!comment) {
            return res.status(404).json({ success: false, message: "Commentaire introuvable" });
        }

        comment.deleteOne();
        post.commentsCount = post.comments.length;
        await post.save();

        res.json({ success: true, message: "Commentaire supprimé" });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    getStats,
    listUsers,
    getUserById,
    updateRole,
    updateStatus,
    deleteUser,
    listPosts,
    deletePost,
    deleteComment,
};
