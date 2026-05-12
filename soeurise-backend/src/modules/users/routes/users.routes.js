const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const { optionalAuth } = require("../../../middlewares/optionalAuth");
const { uploadAvatar } = require("../../../middlewares/uploadAvatar");
const usersController = require("../controllers/users.controller");

// GET /api/users/search-users — rechercher utilisateurs (DOIT ÊTRE AVANT /:id)
router.get("/search-users", requireAuth, usersController.searchUsers);

// GET /api/users/me — profil connecté
router.get("/me", requireAuth, usersController.getMe);

// GET /api/users/me/follow-requests — demandes reçues (compte privé)
router.get("/me/follow-requests", requireAuth, usersController.getMyFollowRequests);

// GET /api/users/me/followers — followers de l'utilisateur courant
router.get("/me/followers", requireAuth, usersController.getMyFollowers);

// GET /api/users/me/following — abonnements de l'utilisateur courant
router.get("/me/following", requireAuth, usersController.getMyFollowing);

// GET /api/users/me/blocked — utilisateurs bloqués
router.get("/me/blocked", requireAuth, usersController.getBlockedUsers);

// POST /api/users/me/follow-requests/:userId/accept|decline
router.post(
    "/me/follow-requests/:userId/accept",
    requireAuth,
    usersController.acceptFollowRequest
);
router.post(
    "/me/follow-requests/:userId/decline",
    requireAuth,
    usersController.declineFollowRequest
);

// GET /api/users/:id — profil public (with optional auth for follow status)
// GET /api/users/:id — profil public (with optional auth for follow status)
router.get("/:id", optionalAuth, usersController.getUserById);

// GET /api/users/:userId/followers — followers d'un utilisateur spécifique
router.get("/:userId/followers", optionalAuth, usersController.getUserFollowers);

// GET /api/users/:userId/following — abonnements d'un utilisateur spécifique
router.get("/:userId/following", optionalAuth, usersController.getUserFollowing);

// Toutes les routes suivantes nécessitent auth
router.use(requireAuth);

// PUT /api/users/me — modifier profil (firstName, lastName, username, email)
router.put("/me", usersController.updateMe);

// PUT /api/users/me/avatar — upload/remplacer avatar
router.put("/me/avatar", uploadAvatar.single("avatar"), usersController.updateAvatar);

// DELETE /api/users/me/avatar — supprimer avatar
router.delete("/me/avatar", usersController.deleteAvatar);

// POST /api/users/:id/follow — suivre/ne plus suivre un utilisateur
const postsController = require("../../posts/controllers/posts.controller");
router.post("/:id/follow", postsController.toggleFollow);

// POST /api/users/:id/block — bloquer un utilisateur
router.post("/:id/block", usersController.blockUser);

// POST /api/users/:id/unblock — débloquer un utilisateur
router.post("/:id/unblock", usersController.unblockUser);

module.exports = router;
