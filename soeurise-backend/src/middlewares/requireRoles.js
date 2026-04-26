/**
 * Middleware: requireRoles
 * Vérifie que l'utilisateur authentifié a un rôle autorisé.
 * Usage: requireRoles(["admin", "staff"])
 */
function requireRoles(allowedRoles) {
  return (req, res, next) => {
    // Vérifier que requireAuth a été appelé avant
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authentification requise",
      });
    }

    // Vérifier le rôle
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "Accès non autorisé - rôle insuffisant",
      });
    }

    next();
  };
}

module.exports = { requireRoles };
