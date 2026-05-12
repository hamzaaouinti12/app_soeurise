const User = require("../models/User");
const { deleteFileSafe } = require("../../../utils/file");
const notificationsService = require("../../notifications/services/notifications.service");

/**
 * Mettre à jour le profil (firstName, lastName, username, email)
 * Vérifie l'unicité username/email
 */
async function updateProfile(userId, data) {
    const { firstName, lastName, username, email, accountPrivacy } = data;
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
    if (accountPrivacy !== undefined) {
        user.accountPrivacy = accountPrivacy;
    }
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

/**
 * Demandes d'abonnement reçues par l'utilisateur connecté (profil privé).
 */
async function listIncomingFollowRequests(userId) {
    const user = await User.findById(userId)
        .select("pendingFollowRequests")
        .populate("pendingFollowRequests", "firstName lastName username avatarUrl");
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }
    const list = user.pendingFollowRequests || [];
    return list.map((u) => {
        if (!u) return null;
        const p = u.toPublic ? u.toPublic() : u;
        const { email: _e, ...safe } = p;
        return safe;
    }).filter(Boolean);
}

/**
 * Accepter une demande → abonné + retiré des demandes en attente
 */
async function acceptFollowRequest(ownerId, requesterId) {
    const owner = await User.findById(ownerId);
    const requester = await User.findById(requesterId);
    if (!owner || !requester) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }
    if (!owner.pendingFollowRequests.some((id) => id.toString() === requesterId.toString())) {
        const err = new Error("Aucune demande en attente pour cet utilisateur");
        err.statusCode = 404;
        throw err;
    }
    owner.pendingFollowRequests.pull(requesterId);
    if (!owner.followers.includes(requesterId)) {
        owner.followers.push(requesterId);
    }
    if (!requester.following.includes(ownerId)) {
        requester.following.push(ownerId);
    }
    await owner.save();
    await requester.save();

    await notificationsService.createNotification({
        recipient: requesterId,
        sender: ownerId,
        type: "follow",
        text: `${owner.username} a accepté votre demande d'abonnement`,
    });

    return { message: "Demande acceptée" };
}

/**
 * Refuser ou annuler une demande sans créer la relation follow
 */
async function declineFollowRequest(ownerId, requesterId) {
    const owner = await User.findById(ownerId);
    if (!owner) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }
    if (!owner.pendingFollowRequests.some((id) => id.toString() === requesterId.toString())) {
        const err = new Error("Aucune demande en attente pour cet utilisateur");
        err.statusCode = 404;
        throw err;
    }
    owner.pendingFollowRequests.pull(requesterId);
    await owner.save();
    return { message: "Demande refusée" };
}

/**
 * Bloquer un utilisateur
 */
async function blockUser(userId, targetUserId) {
    if (userId.toString() === targetUserId.toString()) {
        const err = new Error("Vous ne pouvez pas vous bloquer vous-même");
        err.statusCode = 400;
        throw err;
    }

    const user = await User.findById(userId);
    const target = await User.findById(targetUserId);

    if (!user || !target) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Ajouter à la liste des bloqués si pas déjà présent
    const alreadyBlocked = user.blockedUsers.some(id => id.toString() === targetUserId.toString());
    if (!alreadyBlocked) {
        user.blockedUsers.push(targetUserId);
    }

    // Supprimer les relations de suivi
    user.following.pull(targetUserId);
    user.followers.pull(targetUserId);
    user.pendingFollowRequests.pull(targetUserId);

    target.following.pull(userId);
    target.followers.pull(userId);
    target.pendingFollowRequests.pull(userId);

    console.log(`User ${userId} blocking ${targetUserId}`);
    await user.save();
    await target.save();
    console.log("Block saved successfully");

    return { message: "Utilisateur bloqué" };
}

/**
 * Débloquer un utilisateur
 */
async function unblockUser(userId, targetUserId) {
    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    user.blockedUsers.pull(targetUserId);
    await user.save();

    return { message: "Utilisateur débloqué" };
}

/**
 * Rechercher des utilisateurs par username ou nom
 */
async function searchUsers(query, limit = 10) {
    if (!query || query.trim().length < 2) return [];

    const parts = query.trim().split(/\s+/).filter(p => p.length > 0);
    if (parts.length === 0) return [];

    // Chaque mot doit matcher au moins un des champs
    const searchConditions = parts.map(part => ({
        $or: [
            { username: new RegExp(part, "i") },
            { firstName: new RegExp(part, "i") },
            { lastName: new RegExp(part, "i") },
        ]
    }));

    const users = await User.find({
        $and: searchConditions,
        isActive: true,
    })
    .limit(limit);

    return users.map(u => u.toPublic());
}

/**
 * Liste des utilisateurs bloqués par l'utilisateur connecté
 */
async function listBlockedUsers(userId) {
    console.log("Fetching blocked users for:", userId);
    const user = await User.findById(userId)
        .populate("blockedUsers", "_id firstName lastName username email avatarUrl role isActive accountPrivacy createdAt following followers pendingFollowRequests");
    
    if (!user) {
        console.log("User not found:", userId);
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    console.log("Found blocked users count:", (user.blockedUsers || []).length);

    return (user.blockedUsers || []).map(u => {
        if (!u) return null;
        if (typeof u.toPublic === 'function') {
            return u.toPublic();
        }
        return {
            id: u._id,
            firstName: u.firstName,
            lastName: u.lastName,
            username: u.username,
            avatarUrl: u.avatarUrl
        };
    }).filter(Boolean);
}

module.exports = {
    updateProfile,
    updateAvatar,
    deleteAvatar,
    listIncomingFollowRequests,
    acceptFollowRequest,
    declineFollowRequest,
    blockUser,
    unblockUser,
    searchUsers,
    listBlockedUsers,
};
