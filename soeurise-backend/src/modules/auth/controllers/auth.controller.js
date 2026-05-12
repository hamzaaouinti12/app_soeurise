const { registerSchema, loginSchema } = require("../validators/auth.validators");
const authService = require("../services/auth.service");

async function register(req, res, next) {
  try {
    // validation
    const { error, value } = registerSchema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        success: false,
        errors: error.details.map((d) => d.message),
      });
    }

    // passwordConfirm n'est pas nécessaire dans le service
    const { passwordConfirm, ...clean } = value;

    // ✅ récupérer le fichier uploadé (champ: avatar)
    const avatar = req.file
      ? {
          avatarUrl: `/uploads/avatars/${req.file.filename}`,
          avatarMime: req.file.mimetype,
        }
      : null;

    // ✅ passer avatar au service
    const result = await authService.register(clean, avatar);

    return res.status(201).json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { error, value } = loginSchema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        success: false,
        errors: error.details.map((d) => d.message),
      });
    }

    const result = await authService.login(value);
    return res.status(200).json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login };
