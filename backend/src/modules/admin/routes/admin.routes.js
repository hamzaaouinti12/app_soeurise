const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { requireRoles } = require("../../../middlewares/requireRoles");
const adminController = require("../controllers/admin.controller");

// Toutes les routes admin nécessitent: auth + rôle admin
router.use(requireAuth);
router.use(requireRoles(["admin"]));

// GET /api/admin/users - Liste paginée avec recherche
router.get("/users", adminController.listUsers);

// GET /api/admin/users/:id - Détail d'un user
router.get("/users/:id", adminController.getUserById);

// PATCH /api/admin/users/:id/role - Modifier le rôle
router.patch("/users/:id/role", adminController.updateRole);

// PATCH /api/admin/users/:id/status - Activer/désactiver
router.patch("/users/:id/status", adminController.updateStatus);

// DELETE /api/admin/users/:id - Supprimer user + avatar
router.delete("/users/:id", adminController.deleteUser);

module.exports = router;
