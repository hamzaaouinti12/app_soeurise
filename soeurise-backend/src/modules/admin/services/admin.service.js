const User = require("../../users/models/User");
const { deleteFileSafe } = require("../../../utils/file");
const { formatPagination } = require("../../../utils/pagination");

/**
 * Liste des utilisateurs avec pagination et recherche
 */
async function listUsers(page, limit, search) {
    const skip = (page - 1) * limit;

    // Filtre de recherche sur email ou username
    const filter = {};
    if (search && search.trim()) {
        const regex = new RegExp(search.trim(), "i");
        filter.$or = [{ email: regex }, { username: regex }];
    }

    const [users, total] = await Promise.all([
        User.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
        User.countDocuments(filter),
    ]);

    return {
        users: users.map((u) => u.toPublic()),
        pagination: formatPagination(page, limit, total),
    };
}

/**
 * Récupérer un utilisateur par ID
 */
async function getUserById(id) {
    const user = await User.findById(id);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }
    return user.toPublic();
}

/**
 * Modifier le rôle d'un utilisateur
 */
async function updateUserRole(id, role) {
    const user = await User.findById(id);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    user.role = role;
    await user.save();

    return user.toPublic();
}

/**
 * Activer/désactiver un utilisateur
 */
async function updateUserStatus(id, isActive) {
    const user = await User.findById(id);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    user.isActive = isActive;
    await user.save();

    return user.toPublic();
}

/**
 * Supprimer un utilisateur et son fichier avatar
 */
async function deleteUser(id, requestingUserId) {
    // Empêcher l'admin de se supprimer lui-même
    if (id === requestingUserId.toString()) {
        const err = new Error("Vous ne pouvez pas supprimer votre propre compte");
        err.statusCode = 403;
        throw err;
    }

    const user = await User.findById(id);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Supprimer le fichier avatar s'il existe
    await deleteFileSafe(user.avatarUrl);

    await User.findByIdAndDelete(id);

    return { message: "Utilisateur supprimé avec succès" };
}

module.exports = {
    listUsers,
    getUserById,
    updateUserRole,
    updateUserStatus,
    deleteUser,
};
