const usersService = require("../services/users.service");
const { updateProfileSchema } = require("../validators/users.validators");

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

module.exports = { getMe, updateMe, updateAvatar, deleteAvatar };
