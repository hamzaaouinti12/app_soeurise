const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const { uploadAvatar } = require("../../../middlewares/uploadAvatar");
const usersController = require("../controllers/users.controller");

// Toutes les routes nécessitent auth
router.use(requireAuth);

// GET /api/users/me — profil connecté
router.get("/me", usersController.getMe);

// PUT /api/users/me — modifier profil (firstName, lastName, username, email)
router.put("/me", usersController.updateMe);

// PUT /api/users/me/avatar — upload/remplacer avatar
router.put("/me/avatar", uploadAvatar.single("avatar"), usersController.updateAvatar);

// DELETE /api/users/me/avatar — supprimer avatar
router.delete("/me/avatar", usersController.deleteAvatar);

// POST /api/users/:id/follow — suivre/ne plus suivre un utilisateur
const postsController = require("../../posts/controllers/posts.controller");
router.post("/:id/follow", postsController.toggleFollow);

module.exports = router;
