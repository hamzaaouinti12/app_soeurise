const messagesService = require("../services/messages.service");

async function sendPrivateMessage(req, res, next) {
  try {
    const { recipientId, text, audioDurationMs, replyTo, storyImageUrl } = req.body;
    if (!recipientId) {
      return res.status(400).json({ success: false, message: "Recipient required" });
    }

    const hasText = text && text.toString().trim().length > 0;
    const hasFile = !!req.file;
    if (!hasText && !hasFile) {
      return res.status(400).json({ success: false, message: "Message vide" });
    }

    const durationParsed = audioDurationMs ? parseInt(audioDurationMs, 10) : null;
    const durationMs = Number.isFinite(durationParsed) ? durationParsed : null;

    const message = await messagesService.sendMessage(
      req.user._id,
      recipientId,
      text,
      req.user.username,
      req.file || null,
      {
        audioDurationMs: durationMs,
        replyTo: replyTo || null,
        storyImageUrl: storyImageUrl || null,
      }
    );

    res.status(201).json({ success: true, data: { message } });
  } catch (err) {
    next(err);
  }
}

async function getChat(req, res, next) {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : 50;
    const messages = await messagesService.getChatHistory(
      req.user._id,
      req.params.otherUserId,
      limit
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

async function markChatRead(req, res, next) {
  try {
    const count = await messagesService.markChatRead(
      req.user._id,
      req.params.otherUserId
    );
    res.json({ success: true, data: { count } });
  } catch (err) {
    next(err);
  }
}

async function deleteMessage(req, res, next) {
  try {
    await messagesService.deleteMessageForAll(req.params.messageId, req.user._id);
    res.json({ success: true, message: "Message supprime" });
  } catch (err) {
    next(err);
  }
}

async function editMessage(req, res, next) {
  try {
    const { newText } = req.body;
    if (!newText || newText.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Le texte ne peut pas être vide" });
    }
    const message = await messagesService.editMessage(req.params.messageId, req.user._id, newText);
    res.json({ success: true, data: { message } });
  } catch (err) {
    next(err);
  }
}

async function reactToMessage(req, res, next) {
  try {
    const { reactionType } = req.body;
    if (!reactionType) {
      return res.status(400).json({ success: false, message: "Type de réaction requis" });
    }
    const message = await messagesService.reactToMessage(req.params.messageId, req.user._id, reactionType);
    res.json({ success: true, data: { message } });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  sendPrivateMessage,
  getChat,
  getConversations,
  markChatRead,
  deleteMessage,
  editMessage,
  reactToMessage,
};
