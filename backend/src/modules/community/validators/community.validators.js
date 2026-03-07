const Joi = require("joi");

const objectIdRegex = /^[a-fA-F0-9]{24}$/;

/**
 * POST /api/community/groups
 */
const createGroupSchema = Joi.object({
    name: Joi.string().trim().min(3).max(80).required().messages({
        "any.required": "Le nom du groupe est requis",
        "string.min": "Le nom doit contenir au moins 3 caractères",
        "string.max": "Le nom ne peut pas dépasser 80 caractères",
    }),
    description: Joi.string().trim().max(500).allow("").default("").messages({
        "string.max": "La description ne peut pas dépasser 500 caractères",
    }),
    isPublic: Joi.boolean().default(true),
    requiresSubscription: Joi.boolean().default(false),
});

/**
 * GET /api/community/groups/public
 */
const listPublicSchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(50).default(10),
    search: Joi.string().trim().max(100).allow("").default(""),
});

/**
 * Param :id
 */
const groupIdSchema = Joi.object({
    id: Joi.string().pattern(objectIdRegex).required().messages({
        "string.pattern.base": "ID de groupe invalide",
    }),
});

/**
 * PATCH /api/community/groups/:id/requests/:memberId
 */
const handleRequestSchema = Joi.object({
    action: Joi.string().valid("accept", "reject").required().messages({
        "any.only": "L'action doit être: accept ou reject",
        "any.required": "L'action est requise",
    }),
});

/**
 * POST /api/community/groups/:id/members
 */
const addMemberSchema = Joi.object({
    userId: Joi.string().pattern(objectIdRegex).required().messages({
        "string.pattern.base": "ID utilisateur invalide",
        "any.required": "L'ID utilisateur est requis",
    }),
    roleInGroup: Joi.string().valid("member", "moderator").default("member").messages({
        "any.only": "Le rôle doit être: member ou moderator",
    }),
});

/**
 * PATCH /api/community/groups/:id/members/:memberId
 */
const updateMemberSchema = Joi.object({
    roleInGroup: Joi.string().valid("member", "moderator", "owner"),
    status: Joi.string().valid("active", "banned"),
}).min(1).messages({
    "object.min": "Au moins un champ (roleInGroup ou status) est requis",
});

/**
 * Param :memberId
 */
const memberIdSchema = Joi.object({
    id: Joi.string().pattern(objectIdRegex).required(),
    memberId: Joi.string().pattern(objectIdRegex).required().messages({
        "string.pattern.base": "ID membre invalide",
    }),
});

module.exports = {
    createGroupSchema,
    listPublicSchema,
    groupIdSchema,
    handleRequestSchema,
    addMemberSchema,
    updateMemberSchema,
    memberIdSchema,
};
