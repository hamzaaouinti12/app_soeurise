/**
 * Middleware: requireAdmin
 * Raccourci pour requireRoles(["admin"])
 * Usage: router.get("/route", requireAuth, requireAdmin, handler)
 */
const { requireRoles } = require("./requireRoles");

const requireAdmin = requireRoles(["admin"]);

module.exports = { requireAdmin };
