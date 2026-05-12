const communityService = require("../services/community.service");
const {
    createGroupSchema,
    listPublicSchema,
    groupIdSchema,
    handleRequestSchema,
    addMemberSchema,
    updateMemberSchema,
    memberIdSchema,
    sendMessageSchema,
    updateGroupSchema,
    messageIdSchema,
} = require("../validators/community.validators");


// ──────────────────────────────────────────
//  Phase 3-4: handlers existants
// ──────────────────────────────────────────

async function createGroup(req, res, next) {
    try {
        const { error, value } = createGroupSchema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const group = await communityService.createGroup(
            req.user._id,
            value,
            req.file || null
        );

        res.status(201).json({
            success: true,
            message: "Groupe créé avec succès",
            data: { group },
        });
    } catch (err) {
        next(err);
    }
}

async function listPublicGroups(req, res, next) {
    try {
        const { error, value } = listPublicSchema.validate(req.query);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const data = await communityService.listPublicGroups(
            value.page,
            value.limit,
            value.search,
            req.user ? req.user._id : null
        );

        res.json({ success: true, data });
    } catch (err) {
        next(err);
    }
}

async function getGroup(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.canViewGroup(
            req.params.id,
            req.user ? req.user._id : null
        );

        if (!result.canView) {
            return res.status(403).json({
                success: false,
                message: "Accès non autorisé à ce groupe",
            });
        }

        const subResult = await communityService.isSubscribed(
            req.params.id,
            req.user ? req.user._id : null
        );

        res.json({
            success: true,
            data: {
                group: result.group,
                isSubscribed: subResult.subscribed,
                subscription: subResult.subscription,
            },
        });
    } catch (err) {
        next(err);
    }
}

async function joinGroup(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.joinGroup(
            req.params.id,
            req.user._id
        );

        res.status(201).json({
            success: true,
            message: result.message,
            data: { membership: result.membership },
        });
    } catch (err) {
        next(err);
    }
}

async function getMyMembership(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.getMembership(
            req.params.id,
            req.user._id
        );

        res.json({
            success: true,
            data: {
                status: result.status,
                roleInGroup: result.roleInGroup,
                membership: result.membership,
            },
        });
    } catch (err) {
        next(err);
    }
}

async function getMySubscription(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.getSubscription(
            req.params.id,
            req.user._id
        );

        res.json({
            success: true,
            data: {
                isSubscribed: result.isSubscribed,
                plan: result.plan,
                status: result.status,
                subscription: result.subscription,
            },
        });
    } catch (err) {
        next(err);
    }
}

// ──────────────────────────────────────────
//  Chat Messages
// ──────────────────────────────────────────

async function getGroupMessages(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const messages = await communityService.getGroupMessages(
            req.params.id,
            req.user._id,
            req.query.limit ? parseInt(req.query.limit, 10) : 50
        );

        res.json({
            success: true,
            data: { messages },
        });
    } catch (err) {
        next(err);
    }
}

async function sendMessage(req, res, next) {
    try {
        const { error: paramError } = groupIdSchema.validate(req.params);
        if (paramError) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const { error, value } = sendMessageSchema.validate(req.body, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const { text, replyTo } = value;

        const message = await communityService.sendMessage(
            req.params.id,
            req.user._id,
            text,
            replyTo
        );

        res.status(201).json({
            success: true,
            message: "Message envoyé",
            data: { message },
        });
    } catch (err) {
        next(err);
    }
}

// ──────────────────────────────────────────
//  Phase 5: gestion membres & demandes
// ──────────────────────────────────────────

/**
 * GET /api/community/groups/:id/requests
 */
async function listRequests(req, res, next) {
    try {
        const requests = await communityService.listPendingRequests(req.params.id);
        res.json({ success: true, data: { requests } });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/community/groups/:id/requests/:memberId
 */
async function handleRequest(req, res, next) {
    try {
        const { error: pError } = memberIdSchema.validate(req.params);
        if (pError) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
            });
        }

        const { error, value } = handleRequestSchema.validate(req.body, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const result = await communityService.handleRequest(
            req.params.id,
            req.params.memberId,
            value.action
        );

        res.json({
            success: true,
            message: result.message,
            data: { membership: result.membership },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/community/groups/:id/members
 */
async function addMember(req, res, next) {
    try {
        const { error, value } = addMemberSchema.validate(req.body, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const member = await communityService.addMember(
            req.params.id,
            value.userId,
            value.roleInGroup
        );

        res.status(201).json({
            success: true,
            message: "Membre ajouté avec succès",
            data: { member },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/community/groups/:id/members/:memberId
 */
async function updateMember(req, res, next) {
    try {
        const { error: pError } = memberIdSchema.validate(req.params);
        if (pError) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
            });
        }

        const { error, value } = updateMemberSchema.validate(req.body, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const member = await communityService.updateMember(
            req.params.id,
            req.params.memberId,
            value
        );

        res.json({
            success: true,
            message: "Membre mis à jour",
            data: { member },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * DELETE /api/community/groups/:id/members/:memberId
 */
async function removeMember(req, res, next) {
    try {
        const { error } = memberIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
            });
        }

        const result = await communityService.removeMember(
            req.params.id,
            req.params.memberId
        );

        res.json({
            success: true,
            message: result.message,
        });
    } catch (err) {
        next(err);
    }
}

// ──────────────────────────────────────────
//  Phase 6: vue membres, mise à jour groupe, suppression message
// ──────────────────────────────────────────

/**
 * GET /api/community/groups/:id/members
 */
async function getGroupMembers(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const members = await communityService.getGroupMembers(
            req.params.id,
            req.user._id
        );

        res.json({ success: true, data: { members } });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/community/groups/:id
 */
async function updateGroup(req, res, next) {
    try {
        const { error: pError } = groupIdSchema.validate(req.params);
        if (pError) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const { error, value } = updateGroupSchema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const group = await communityService.updateGroup(
            req.params.id,
            value,
            req.file || null
        );

        res.json({
            success: true,
            message: "Groupe mis à jour",
            data: { group },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * DELETE /api/community/groups/:id/messages/:messageId
 */
async function deleteMessage(req, res, next) {
    try {
        const { error } = messageIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
            });
        }

        const result = await communityService.deleteGroupMessage(
            req.params.id,
            req.params.messageId,
            req.user._id
        );

        res.json({ success: true, message: result.message });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/community/groups/:id/messages/read
 */
async function markMessagesRead(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({ success: false, message: "ID de groupe invalide" });
        }
        const result = await communityService.markMessagesRead(req.params.id, req.user._id);
        res.json({ success: true, data: result });
    } catch (err) {
        next(err);
    }
}

async function editGroupMessage(req, res, next) {
    try {
        const { newText } = req.body;
        if (!newText || !newText.trim()) {
            return res.status(400).json({ success: false, message: "Le texte ne peut pas être vide" });
        }
        const message = await communityService.editGroupMessage(
            req.params.id,
            req.params.messageId,
            req.user._id,
            newText
        );
        res.json({ success: true, data: { message } });
    } catch (err) {
        next(err);
    }
}

async function reactToGroupMessage(req, res, next) {
    try {
        const { reactionType } = req.body;
        if (!reactionType) {
            return res.status(400).json({ success: false, message: "Type de réaction requis" });
        }
        const message = await communityService.reactToGroupMessage(
            req.params.id,
            req.params.messageId,
            req.user._id,
            reactionType
        );
        res.json({ success: true, data: { message } });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    createGroup,
    listPublicGroups,
    getGroup,
    joinGroup,
    getMyMembership,
    getMySubscription,
    getGroupMessages,
    sendMessage,
    markMessagesRead,
    // Phase 5
    listRequests,
    handleRequest,
    addMember,
    updateMember,
    removeMember,
    // Phase 6
    getGroupMembers,
    updateGroup,
    deleteMessage,
    editGroupMessage,
    reactToGroupMessage,
};
