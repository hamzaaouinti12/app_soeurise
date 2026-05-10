const messagesService = require("../services/messages.service");

async function sendPrivateMessage(req, res, next) {
  try {
    const { recipientId, text } = req.body;
    if (!recipientId || !text) {
      return res.status(400).json({ success: false, message: "Recipient and text required" });
    }

    const message = await messagesService.sendMessage(
      req.user._id,
      recipientId,
      text,
      req.user.username
    );

    res.status(201).json({ success: true, data: { message } });
  } catch (err) {
    next(err);
  }
}

async function getChat(req, res, next) {
  try {
    const messages = await messagesService.getChatHistory(
      req.user._id,
      req.params.otherUserId
    );
    res.json({ success: true, data: { messages } });
  } catch (err) {
    next(err);
  }
}

async function getConversations(req, res, next) {
    try {
        const conversations = await messagesService.getConversations(req.user._id);
        res.json({ success: true, data: { conversations } });
    } catch (err) {
        next(err);
    }
}

module.exports = {
  sendPrivateMessage,
  getChat,
  getConversations,
};
