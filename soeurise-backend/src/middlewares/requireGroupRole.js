const GroupMember = require("../modules/community/models/GroupMember");

/**
 * Middleware: requireGroupRole
 * Vérifie que l'utilisateur a un rôle suffisant dans le groupe.
 * L'admin global (req.user.role === "admin") a tous les droits.
 * Sinon, vérifie le roleInGroup parmi les allowedRoles.
 *
 * Usage: requireGroupRole(["owner", "moderator"])
 * Le groupId est lu depuis req.params.id
 */
function requireGroupRole(allowedRoles) {
    return async (req, res, next) => {
        try {
            // Admin global → accès total
            if (req.user.role === "admin") {
                return next();
            }

            const groupId = req.params.id;
            if (!groupId) {
                return res.status(400).json({
                    success: false,
                    message: "ID de groupe manquant",
                });
            }

            const member = await GroupMember.findOne({
                groupId,
                userId: req.user._id,
                status: "active",
            });

            if (!member) {
                return res.status(403).json({
                    success: false,
                    message: "Vous n'êtes pas membre actif de ce groupe",
                });
            }

            if (!allowedRoles.includes(member.roleInGroup)) {
                return res.status(403).json({
                    success: false,
                    message: "Permissions insuffisantes dans ce groupe",
                });
            }

            // Stocker pour usage dans le controller
            req.groupMember = member;
            next();
        } catch (err) {
            return res.status(500).json({
                success: false,
                message: "Erreur de vérification des permissions",
            });
        }
    };
}

module.exports = { requireGroupRole };
