const Joi = require("joi");

// Validation ObjectId MongoDB
const objectIdRegex = /^[a-fA-F0-9]{24}$/;

/**
 * Query params pour liste des users
 */
const listUsersSchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(10),
    search: Joi.string().trim().max(100).allow("").default(""),
});

/**
 * Param :id (MongoDB ObjectId)
 */
const userIdSchema = Joi.object({
    id: Joi.string().pattern(objectIdRegex).required().messages({
        "string.pattern.base": "ID utilisateur invalide",
        "any.required": "ID utilisateur requis",
    }),
});

/**
 * Body pour modifier le rôle
 */
const updateRoleSchema = Joi.object({
    role: Joi.string().valid("user", "staff", "admin").required().messages({
        "any.only": "Le rôle doit être: user, staff ou admin",
        "any.required": "Le rôle est requis",
    }),
});

/**
 * Body pour modifier le statut isActive
 */
const updateStatusSchema = Joi.object({
    isActive: Joi.boolean().required().messages({
        "any.required": "Le statut isActive est requis",
    }),
});

module.exports = {
    listUsersSchema,
    userIdSchema,
    updateRoleSchema,
    updateStatusSchema,
};
