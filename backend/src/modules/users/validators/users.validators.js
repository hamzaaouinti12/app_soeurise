const Joi = require("joi");

/**
 * PUT /api/users/me
 * Modifiable: firstName, lastName, username, email
 * Interdit:   role, isActive (strippés)
 */
const updateProfileSchema = Joi.object({
    firstName: Joi.string().trim().min(2).max(50).required().messages({
        "any.required": "Prénom requis",
        "string.min": "Le prénom doit contenir au moins 2 caractères",
        "string.max": "Le prénom ne peut pas dépasser 50 caractères",
    }),
    lastName: Joi.string().trim().min(2).max(50).required().messages({
        "any.required": "Nom de famille requis",
        "string.min": "Le nom doit contenir au moins 2 caractères",
        "string.max": "Le nom ne peut pas dépasser 50 caractères",
    }),
    username: Joi.string().trim().min(3).max(30).required().messages({
        "any.required": "Nom d'utilisateur requis",
        "string.min": "Le nom d'utilisateur doit contenir au moins 3 caractères",
        "string.max": "Le nom d'utilisateur ne peut pas dépasser 30 caractères",
    }),
    email: Joi.string().email().required().messages({
        "any.required": "Email requis",
        "string.email": "Email invalide",
    }),
});

module.exports = { updateProfileSchema };
