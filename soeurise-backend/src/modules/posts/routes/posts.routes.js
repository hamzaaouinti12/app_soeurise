const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { uploadPostImage } = require("../../../middlewares/uploadPostImage");
const postsController = require("../controllers/posts.controller");

// Toutes les routes posts nécessitent d'être connecté
router.use(requireAuth);

// GET /api/posts - Récupérer le fil d'actualité global ou par communauté
router.get("/", postsController.getFeed);

// GET /api/posts/user/:userId - Récupérer les publications d'un utilisateur
router.get("/user/:userId", postsController.getUserPosts);

// GET /api/posts/saved - Récupérer les publications sauvegardées
router.get("/saved", postsController.getSavedPosts);

// GET /api/posts/subscriptions - Fil d'actualité des abonnements
router.get("/subscriptions", postsController.getSubscriptionFeed);

// POST /api/posts - Créer un nouveau post
router.post("/", uploadPostImage.single("image"), postsController.createPost);

// POST /api/posts/:id/like - Liker/Unliker un post
router.post("/:id/like", postsController.toggleLike);

// POST /api/posts/:id/share - Partager un post
router.post("/:id/share", postsController.sharePost);

// DELETE /api/posts/:id - Supprimer un post
router.delete("/:id", postsController.deletePost);

// PUT /api/posts/:id - Modifier un post
router.put("/:id", postsController.updatePost);

// POST /api/posts/:id/pin - Epingler/Desepingler un post
router.post("/:id/pin", postsController.togglePinPost);

// POST /api/posts/:id/save - Sauvegarder/retirer une publication
router.post("/:id/save", postsController.toggleSave);

// POST /api/posts/:id/comments/:commentId/hide - Masquer/Afficher un commentaire
router.post("/:id/comments/:commentId/hide", postsController.toggleHideComment);

// POST /api/posts/:id/comments/:commentId/pin - Épingler/Désépingler un commentaire
router.post("/:id/comments/:commentId/pin", postsController.togglePinComment);

// POST /api/posts/:id/comments/:commentId/reply - Répondre à un commentaire
router.post("/:id/comments/:commentId/reply", postsController.replyToComment);

// POST /api/posts/:id/comments/:commentId/like - Liker un commentaire
router.post("/:id/comments/:commentId/like", postsController.likeComment);

// PUT /api/posts/:id/comments/:commentId - Modifier un commentaire
router.put("/:id/comments/:commentId", postsController.updateComment);

// DELETE /api/posts/:id/comments/:commentId - Supprimer un commentaire
router.delete("/:id/comments/:commentId", postsController.deleteComment);

// GET /api/posts/:id/comments - Récupérer les commentaires d'un post
router.get("/:id/comments", postsController.getComments);

// POST /api/posts/:id/comments - Ajouter un commentaire
router.post("/:id/comments", postsController.addComment);

// POST /api/posts/:id/toggle-comments - Désactiver/Activer les commentaires
router.post("/:id/toggle-comments", postsController.toggleCommentsDisabled);

module.exports = router;
