const Joi = require("joi");

const registerSchema = Joi.object({
  firstName: Joi.string().min(2).max(50).required().messages({
    "any.required": "Prénom requis",
  }),
  lastName: Joi.string().min(2).max(50).required().messages({
    "any.required": "Nom de famille requis",
  }),
  username: Joi.string().min(3).max(30).required().messages({
    "any.required": "Nom d'utilisateur requis",
  }),
  email: Joi.string().email().required().messages({
    "any.required": "Email requis",
    "string.email": "Email invalide",
  }),
  password: Joi.string().min(6).max(100).required().messages({
    "any.required": "Mot de passe requis",
  }),
  passwordConfirm: Joi.string().required().valid(Joi.ref("password")).messages({
    "any.required": "Confirmation mot de passe requise",
    "any.only": "Les mots de passe ne correspondent pas",
  }),
});

const loginSchema = Joi.object({
  emailOrUsername: Joi.string().required().messages({
    "any.required": "Email ou nom d'utilisateur requis",
  }),
  password: Joi.string().min(6).max(100).required().messages({
    "any.required": "Mot de passe requis",
  }),
});

module.exports = { registerSchema, loginSchema };
