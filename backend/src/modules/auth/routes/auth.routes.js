const router = require("express").Router();
const authController = require("../controllers/auth.controller");
const { requireAuth } = require("../../../middlewares/auth");
const { uploadAvatar } = require("../../../middlewares/uploadAvatar");

// ✅ Upload field name = "avatar"
router.post("/register", uploadAvatar.single("avatar"), authController.register);

router.post("/login", authController.login);

router.get("/me", requireAuth, (req, res) => {
  res.json({ success: true, user: req.user.toPublic() });
});

module.exports = router;
