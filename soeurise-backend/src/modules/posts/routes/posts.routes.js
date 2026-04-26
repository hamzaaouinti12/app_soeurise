const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { uploadPostImage } = require("../../../middlewares/uploadPostImage");
const postsController = require("../controllers/posts.controller");

// Toutes les routes posts nécessitent d'être connecté
router.use(requireAuth);

// GET /api/posts - Récupérer le fil d'actualité global ou par communauté
router.get("/", postsController.getFeed);

// GET /api/posts/subscriptions - Fil d'actualité des abonnements
router.get("/subscriptions", postsController.getSubscriptionFeed);

// POST /api/posts - Créer un nouveau post
router.post("/", uploadPostImage.single("image"), postsController.createPost);

// POST /api/posts/:id/like - Liker/Unliker un post
router.post("/:id/like", postsController.toggleLike);

// POST /api/posts/:id/share - Partager un post
router.post("/:id/share", postsController.sharePost);

// GET /api/posts/:id/comments - Récupérer les commentaires d'un post
router.get("/:id/comments", postsController.getComments);

// POST /api/posts/:id/comments - Ajouter un commentaire
router.post("/:id/comments", postsController.addComment);

// POST /api/posts/:id/comments/:commentId/reply - Répondre à un commentaire
router.post("/:id/comments/:commentId/reply", postsController.replyToComment);

// POST /api/posts/:id/comments/:commentId/like - Liker un commentaire
router.post("/:id/comments/:commentId/like", postsController.likeComment);

module.exports = router;
