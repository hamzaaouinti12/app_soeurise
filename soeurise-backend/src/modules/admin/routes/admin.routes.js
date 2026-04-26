const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { requireRoles } = require("../../../middlewares/requireRoles");
const adminController = require("../controllers/admin.controller");

// Toutes les routes admin nécessitent: auth + rôle admin
router.use(requireAuth);
router.use(requireRoles(["admin"]));

// GET /api/admin/stats - Statistiques du dashboard
router.get("/stats", adminController.getStats);

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

// GET /api/admin/posts - Liste paginée de tous les posts
router.get("/posts", adminController.listPosts);

// DELETE /api/admin/posts/:id - Supprimer un post
router.delete("/posts/:id", adminController.deletePost);

// DELETE /api/admin/posts/:postId/comments/:commentId - Supprimer un commentaire
router.delete("/posts/:postId/comments/:commentId", adminController.deleteComment);

module.exports = router;
