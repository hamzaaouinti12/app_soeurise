const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { optionalAuth } = require("../../../middlewares/optionalAuth");
const { uploadGroupImage } = require("../../../middlewares/uploadGroupImage");
const { requireGroupRole } = require("../../../middlewares/requireGroupRole");
const communityController = require("../controllers/community.controller");

// ─── PUBLIC ───────────────────────────────────────
router.get("/groups/public", communityController.listPublicGroups);
router.get("/groups/:id", optionalAuth, communityController.getGroup);

// ─── AUTH REQUISE ─────────────────────────────────
router.post(
    "/groups",
    requireAuth,
    uploadGroupImage.single("image"),
    communityController.createGroup
);
router.post("/groups/:id/join", requireAuth, communityController.joinGroup);
router.get("/groups/:id/membership/me", requireAuth, communityController.getMyMembership);
router.get("/groups/:id/subscription/me", requireAuth, communityController.getMySubscription);

// ─── MANAGEMENT (owner/moderator/admin) ───────────
const mgmt = requireGroupRole(["owner", "moderator"]);

router.get("/groups/:id/requests", requireAuth, mgmt, communityController.listRequests);
router.patch("/groups/:id/requests/:memberId", requireAuth, mgmt, communityController.handleRequest);
router.post("/groups/:id/members", requireAuth, mgmt, communityController.addMember);
router.patch("/groups/:id/members/:memberId", requireAuth, mgmt, communityController.updateMember);
router.delete("/groups/:id/members/:memberId", requireAuth, mgmt, communityController.removeMember);

module.exports = router;
