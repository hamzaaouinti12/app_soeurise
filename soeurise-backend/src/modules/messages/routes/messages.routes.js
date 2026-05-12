const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const messagesController = require("../controllers/messages.controller");
const { uploadMessageMedia } = require("../../../middlewares/uploadMessageMedia");

router.use(requireAuth);

router.get("/conversations", messagesController.getConversations);
router.get("/chat/:otherUserId", messagesController.getChat);
router.post("/chat/:otherUserId/read", messagesController.markChatRead);
router.post("/send", uploadMessageMedia.single("media"), messagesController.sendPrivateMessage);
router.post("/:messageId/delete", messagesController.deleteMessage);
router.post("/:messageId/edit", messagesController.editMessage);
router.post("/:messageId/react", messagesController.reactToMessage);

module.exports = router;
