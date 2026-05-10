const Group = require("../models/Group");
const GroupMember = require("../models/GroupMember");
const Subscription = require("../models/Subscription");
const User = require("../../users/models/User");
const GroupMessage = require("../models/GroupMessage");
const { formatPagination } = require("../../../utils/pagination");
const notificationsService = require("../../notifications/services/notifications.service");

// ──────────────────────────────────────────
//  Phase 3-4: fonctions existantes
// ──────────────────────────────────────────

async function createGroup(userId, data, imageFile) {
    const exists = await Group.findOne({ name: data.name });
    if (exists) {
        const err = new Error("Un groupe avec ce nom existe déjà");
        err.statusCode = 409;
        throw err;
    }

    const groupData = {
        name: data.name,
        description: data.description || "",
        isPublic: data.isPublic !== undefined ? data.isPublic : true,
        requiresSubscription: data.requiresSubscription || false,
        createdBy: userId,
    };

    if (imageFile) {
        groupData.imageUrl = `/uploads/groups/${imageFile.filename}`;
        groupData.imageMime = imageFile.mimetype;
    }

    const group = await Group.create(groupData);

    await GroupMember.create({
        groupId: group._id,
        userId: userId,
        roleInGroup: "owner",
        status: "active",
        joinedAt: new Date(),
    });

    return group.toPublic();
}

async function listPublicGroups(page, limit, search) {
    const skip = (page - 1) * limit;
    const filter = { isPublic: true };

    if (search && search.trim()) {
        const regex = new RegExp(search.trim(), "i");
        filter.$or = [{ name: regex }, { description: regex }];
    }

    const [groups, total] = await Promise.all([
        Group.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
        Group.countDocuments(filter),
    ]);

    return {
        groups: groups.map((g) => g.toPublic()),
        pagination: formatPagination(page, limit, total),
    };
}

async function canViewGroup(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    if (group.isPublic) {
        return { canView: true, group: group.toPublic() };
    }

    if (!userId) {
        return { canView: false, group: null };
    }

    const member = await GroupMember.findOne({
        groupId, userId, status: "active",
    });

    return {
        canView: !!member,
        group: member ? group.toPublic() : null,
    };
}

async function joinGroup(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const existing = await GroupMember.findOne({ groupId, userId });
    if (existing) {
        if (existing.status === "banned") {
            const err = new Error("Vous êtes banni de ce groupe");
            err.statusCode = 403;
            throw err;
        }
        if (existing.status === "active") {
            const err = new Error("Vous êtes déjà membre de ce groupe");
            err.statusCode = 409;
            throw err;
        }
        if (existing.status === "pending") {
            const err = new Error("Votre demande d'adhésion est en attente");
            err.statusCode = 409;
            throw err;
        }
    }

    if (group.requiresSubscription) {
        const sub = await Subscription.findOne({
            groupId, userId, status: "active",
        });
        if (!sub) {
            const err = new Error("Une souscription active est requise pour rejoindre ce groupe");
            err.statusCode = 403;
            throw err;
        }
    }

    const status = group.isPublic ? "active" : "pending";

    const member = await GroupMember.create({
        groupId, userId,
        roleInGroup: "member",
        status,
        joinedAt: status === "active" ? new Date() : null,
    });

    return {
        membership: member.toPublic(),
        message: status === "active"
            ? "Vous avez rejoint le groupe"
            : "Demande d'adhésion envoyée, en attente d'approbation",
    };
}

async function getMembership(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const member = await GroupMember.findOne({ groupId, userId });

    if (!member) {
        return { status: "none", roleInGroup: null, membership: null };
    }

    return {
        status: member.status,
        roleInGroup: member.roleInGroup,
        membership: member.toPublic(),
    };
}

async function isSubscribed(groupId, userId) {
    if (!userId) return { subscribed: false, subscription: null };

    const sub = await Subscription.findOne({
        groupId, userId, status: "active",
    });

    return {
        subscribed: !!sub,
        subscription: sub ? sub.toPublic() : null,
    };
}

async function getSubscription(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const sub = await Subscription.findOne({ groupId, userId });

    return {
        isSubscribed: !!sub && sub.status === "active",
        plan: sub ? sub.plan : null,
        status: sub ? sub.status : null,
        subscription: sub ? sub.toPublic() : null,
    };
}

// ──────────────────────────────────────────
//  Chat Messages
// ──────────────────────────────────────────

const { getIO } = require("../../../utils/socket");

async function sendMessage(groupId, userId, text) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const member = await GroupMember.findOne({ groupId, userId, status: "active" });
    if (!member && !group.isPublic) {
        const err = new Error("Seuls les membres actifs peuvent envoyer des messages");
        err.statusCode = 403;
        throw err;
    }

    const message = await GroupMessage.create({
        groupId,
        senderId: userId,
        text,
    });

    await message.populate("senderId", "firstName lastName username avatarUrl");

    const publicMsg = message.toPublic();

    // Emit via socket to the group room
    try {
        const io = getIO();
        io.to(`group_${groupId}`).emit("new_group_message", publicMsg);

        // Also create individual notifications for other active members
        const members = await GroupMember.find({ groupId, status: "active", userId: { $ne: userId } });
        const sender = await User.findById(userId).select("username");
        
        for (const member of members) {
            await notificationsService.createNotification({
                recipient: member.userId,
                sender: userId,
                type: "group_message",
                group: groupId,
                text: `Nouveau message dans le groupe ${group.name} par ${sender.username}`,
            });
        }
    } catch (err) {
        console.error("Socket emit/notification error:", err);
    }

    return publicMsg;
}

async function getGroupMessages(groupId, userId, limit = 50) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Checking if the user can view the group messages
    const { canView } = await canViewGroup(groupId, userId);
    if (!canView) {
        const err = new Error("Accès non autorisé à ce groupe");
        err.statusCode = 403;
        throw err;
    }

    const messages = await GroupMessage.find({ groupId })
        .sort({ createdAt: -1 })
        .limit(limit)
        .populate("senderId", "firstName lastName username avatarUrl");

    // Reverse to send oldest first since sort is descending
    return messages.reverse().map((m) => m.toPublic());
}

// ──────────────────────────────────────────
//  Phase 5: gestion membres & demandes
// ──────────────────────────────────────────

/**
 * Liste des demandes pending pour un groupe
 */
async function listPendingRequests(groupId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const requests = await GroupMember.find({
        groupId, status: "pending",
    }).populate("userId", "firstName lastName username email avatarUrl");

    return requests.map((r) => ({
        id: r._id,
        user: r.userId
            ? {
                id: r.userId._id,
                firstName: r.userId.firstName,
                lastName: r.userId.lastName,
                username: r.userId.username,
                email: r.userId.email,
                avatarUrl: r.userId.avatarUrl,
            }
            : null,
        roleInGroup: r.roleInGroup,
        status: r.status,
        createdAt: r.createdAt,
    }));
}

/**
 * Accepter ou rejeter une demande d'adhésion
 * accept → status "active" + joinedAt
 * reject → supprimer le membership
 */
async function handleRequest(groupId, memberId, action) {
    const member = await GroupMember.findOne({
        _id: memberId,
        groupId,
        status: "pending",
    });

    if (!member) {
        const err = new Error("Demande non trouvée ou déjà traitée");
        err.statusCode = 404;
        throw err;
    }

    if (action === "accept") {
        member.status = "active";
        member.joinedAt = new Date();
        await member.save();
        return { membership: member.toPublic(), message: "Demande acceptée" };
    } else {
        // reject → supprimer le record
        await GroupMember.findByIdAndDelete(memberId);
        return { membership: null, message: "Demande rejetée" };
    }
}

/**
 * Ajouter un membre directement (par owner/moderator/admin)
 */
async function addMember(groupId, targetUserId, roleInGroup) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Vérifier que l'utilisateur cible existe
    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Vérifier doublon
    const existing = await GroupMember.findOne({
        groupId, userId: targetUserId,
    });
    if (existing) {
        const err = new Error("Cet utilisateur est déjà membre ou a une demande en cours");
        err.statusCode = 409;
        throw err;
    }

    // Vérifier subscription si requise
    if (group.requiresSubscription) {
        const sub = await Subscription.findOne({
            groupId, userId: targetUserId, status: "active",
        });
        if (!sub) {
            const err = new Error("L'utilisateur n'a pas de souscription active pour ce groupe");
            err.statusCode = 403;
            throw err;
        }
    }

    const member = await GroupMember.create({
        groupId,
        userId: targetUserId,
        roleInGroup: roleInGroup || "member",
        status: "active",
        joinedAt: new Date(),
    });

    return member.toPublic();
}

/**
 * Modifier le rôle ou le statut d'un membre
 */
async function updateMember(groupId, memberId, updates) {
    const member = await GroupMember.findOne({ _id: memberId, groupId });

    if (!member) {
        const err = new Error("Membre non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Protéger l'owner: on ne peut pas changer le statut de l'owner
    if (member.roleInGroup === "owner" && updates.status === "banned") {
        const err = new Error("Impossible de bannir le propriétaire du groupe");
        err.statusCode = 403;
        throw err;
    }

    if (updates.roleInGroup !== undefined) {
        member.roleInGroup = updates.roleInGroup;
    }
    if (updates.status !== undefined) {
        member.status = updates.status;
        if (updates.status === "active" && !member.joinedAt) {
            member.joinedAt = new Date();
        }
    }

    await member.save();
    return member.toPublic();
}

/**
 * Supprimer un membre du groupe
 */
async function removeMember(groupId, memberId) {
    const member = await GroupMember.findOne({ _id: memberId, groupId });

    if (!member) {
        const err = new Error("Membre non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Protéger l'owner
    if (member.roleInGroup === "owner") {
        const err = new Error("Impossible de supprimer le propriétaire du groupe");
        err.statusCode = 403;
        throw err;
    }

    await GroupMember.findByIdAndDelete(memberId);
    return { message: "Membre supprimé du groupe" };
}

module.exports = {
    createGroup,
    listPublicGroups,
    canViewGroup,
    joinGroup,
    getMembership,
    isSubscribed,
    getSubscription,
    sendMessage,
    getGroupMessages,
    // Phase 5
    listPendingRequests,
    handleRequest,
    addMember,
    updateMember,
    removeMember,
};
