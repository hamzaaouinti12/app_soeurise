const User = require("../models/User");
const { deleteFileSafe } = require("../../../utils/file");

/**
 * Mettre à jour le profil (firstName, lastName, username, email)
 * Vérifie l'unicité username/email
 */
async function updateProfile(userId, data) {
    const { firstName, lastName, username, email } = data;
    const emailLower = email.toLowerCase();

    // Vérifier unicité username (exclure soi-même)
    const usernameExists = await User.findOne({
        username,
        _id: { $ne: userId },
    });
    if (usernameExists) {
        const err = new Error("Ce nom d'utilisateur est déjà utilisé");
        err.statusCode = 409;
        throw err;
    }

    // Vérifier unicité email (exclure soi-même)
    const emailExists = await User.findOne({
        email: emailLower,
        _id: { $ne: userId },
    });
    if (emailExists) {
        const err = new Error("Cet email est déjà utilisé");
        err.statusCode = 409;
        throw err;
    }

    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    user.firstName = firstName;
    user.lastName = lastName;
    user.username = username;
    user.email = emailLower;
    await user.save();

    return user.toPublic();
}

/**
 * Mettre à jour l'avatar (upload nouveau + supprimer ancien fichier)
 */
async function updateAvatar(userId, file) {
    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const oldAvatarUrl = user.avatarUrl;

    user.avatarUrl = `/uploads/avatars/${file.filename}`;
    user.avatarMime = file.mimetype;
    await user.save();

    // Supprimer ancien fichier après save
    await deleteFileSafe(oldAvatarUrl);

    return user.toPublic();
}

/**
 * Supprimer l'avatar (fichier + vider champs)
 */
async function deleteAvatar(userId) {
    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const oldAvatarUrl = user.avatarUrl;

    user.avatarUrl = "";
    user.avatarMime = "";
    await user.save();

    await deleteFileSafe(oldAvatarUrl);

    return user.toPublic();
}

module.exports = { updateProfile, updateAvatar, deleteAvatar };
