const User = require("../../users/models/User");
const { hashPassword, comparePassword } = require("../../../utils/password");
const { signAccessToken } = require("../../../utils/jwt");

// ✅ avatar est optionnel
async function register({ firstName, lastName, username, email, password }, avatar) {
  const emailLower = email.toLowerCase();

  // Check email unique
  const emailExists = await User.findOne({ email: emailLower });
  if (emailExists) {
    const err = new Error("Cet email est déjà utilisé");
    err.statusCode = 409;
    throw err;
  }

  // Check username unique
  const usernameExists = await User.findOne({ username });
  if (usernameExists) {
    const err = new Error("Ce nom d'utilisateur est déjà utilisé");
    err.statusCode = 409;
    throw err;
  }

  const passwordHash = await hashPassword(password);

  // ✅ construire l’objet user à créer
  const userData = {
    firstName,
    lastName,
    username,
    email: emailLower,
    passwordHash,
    role: "user",
  };

  // ✅ si avatar uploadé, on le stocke
  if (avatar) {
    userData.avatarUrl = avatar.avatarUrl;   // ex: /uploads/avatars/avatar_123.png
    userData.avatarMime = avatar.avatarMime; // ex: image/png
  }

  const user = await User.create(userData);

  const token = signAccessToken({ sub: user._id.toString(), role: user.role });

  return { user: user.toPublic(), token };
}

async function login({ emailOrUsername, password }) {
  const key = emailOrUsername.includes("@")
    ? { email: emailOrUsername.toLowerCase() }
    : { username: emailOrUsername };

  const user = await User.findOne(key);
  if (!user) {
    const err = new Error("Identifiants invalides");
    err.statusCode = 401;
    throw err;
  }

  if (!user.isActive) {
    const err = new Error("Compte désactivé");
    err.statusCode = 403;
    throw err;
  }

  const ok = await comparePassword(password, user.passwordHash);
  if (!ok) {
    const err = new Error("Identifiants invalides");
    err.statusCode = 401;
    throw err;
  }

  const token = signAccessToken({ sub: user._id.toString(), role: user.role });

  return { user: user.toPublic(), token };
}

module.exports = { register, login };
