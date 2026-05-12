const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { optionalAuth } = require("../../../middlewares/optionalAuth");
const { uploadGroupImage } = require("../../../middlewares/uploadGroupImage");
const { requireGroupRole } = require("../../../middlewares/requireGroupRole");
const communityController = require("../controllers/community.controller");

// ─── PUBLIC ───────────────────────────────────────
router.get("/groups/public", optionalAuth, communityController.listPublicGroups);
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

// ─── MESSAGES ─────────────────────────────────────
router.get("/groups/:id/messages", requireAuth, communityController.getGroupMessages);
router.post("/groups/:id/messages", requireAuth, communityController.sendMessage);

// ─── MANAGEMENT (owner/moderator/admin) ───────────
const mgmt = requireGroupRole(["owner", "moderator"]);

router.get("/groups/:id/requests", requireAuth, mgmt, communityController.listRequests);
router.patch("/groups/:id/requests/:memberId", requireAuth, mgmt, communityController.handleRequest);
router.post("/groups/:id/members", requireAuth, mgmt, communityController.addMember);
router.patch("/groups/:id/members/:memberId", requireAuth, mgmt, communityController.updateMember);
router.delete("/groups/:id/members/:memberId", requireAuth, mgmt, communityController.removeMember);

// ─── PHASE 6 : membres, update groupe, suppression message, vu ────────────
router.get("/groups/:id/members", requireAuth, communityController.getGroupMembers);
router.patch("/groups/:id", requireAuth, mgmt, uploadGroupImage.single("image"), communityController.updateGroup);
router.delete("/groups/:id/messages/:messageId", requireAuth, communityController.deleteMessage);
router.post("/groups/:id/messages/:messageId/edit", requireAuth, communityController.editGroupMessage);
router.post("/groups/:id/messages/:messageId/react", requireAuth, communityController.reactToGroupMessage);
router.post("/groups/:id/messages/read", requireAuth, communityController.markMessagesRead);

module.exports = router;

