const jwt = require("jsonwebtoken");
const { JWT_SECRET, JWT_EXPIRES_IN } = require("../config/env");

function signAccessToken(payload) {
  if (!JWT_SECRET) throw new Error("JWT_SECRET is missing in .env");
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN || "7d" });
}

function verifyToken(token) {
  if (!JWT_SECRET) throw new Error("JWT_SECRET is missing in .env");
  return jwt.verify(token, JWT_SECRET);
}

module.exports = { signAccessToken, verifyToken };
