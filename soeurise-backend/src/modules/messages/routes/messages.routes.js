const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const messagesController = require("../controllers/messages.controller");

router.use(requireAuth);

router.get("/conversations", messagesController.getConversations);
router.get("/chat/:otherUserId", messagesController.getChat);
router.post("/send", messagesController.sendPrivateMessage);

module.exports = router;
