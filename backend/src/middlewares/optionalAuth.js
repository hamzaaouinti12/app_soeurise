const { verifyToken } = require("../utils/jwt");
const User = require("../modules/users/models/User");

/**
 * Middleware: optionalAuth
 * Si un Bearer token valide est fourni, met req.user.
 * Sinon, continue sans erreur (req.user = null).
 * Utile pour les routes publiques qui affichent plus de données si connecté.
 */
async function optionalAuth(req, res, next) {
    try {
        const header = req.headers.authorization || "";
        const [type, token] = header.split(" ");

        if (type === "Bearer" && token) {
            const decoded = verifyToken(token);
            const user = await User.findById(decoded.sub);
            if (user && user.isActive) {
                req.user = user;
            }
        }
    } catch (err) {
        // Token invalide → on ignore, user reste null
    }
    next();
}

module.exports = { optionalAuth };
