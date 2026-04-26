const adminService = require("../services/admin.service");
const {
    listUsersSchema,
    userIdSchema,
    updateRoleSchema,
    updateStatusSchema,
} = require("../validators/admin.validators");

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

module.exports = {
    listUsers,
    getUserById,
    updateRole,
    updateStatus,
    deleteUser,
};
