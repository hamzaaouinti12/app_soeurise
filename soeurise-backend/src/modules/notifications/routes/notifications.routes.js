const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const notificationsController = require("../controllers/notifications.controller");

router.use(requireAuth);

router.get("/", notificationsController.getNotifications);
router.get("/unread-count", notificationsController.getUnreadCount);
router.post("/mark-all-read", notificationsController.markAllRead);
router.post("/:id/read", notificationsController.markRead);

module.exports = router;
