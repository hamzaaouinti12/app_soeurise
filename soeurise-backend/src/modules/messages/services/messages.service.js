const PrivateMessage = require("../models/PrivateMessage");
const notificationsService = require("../../notifications/services/notifications.service");
const { sendToUser } = require("../../../utils/socket");

function normalizeUser(doc) {
  if (!doc) return null;
  if (typeof doc.toPublic === "function") return doc.toPublic();
  return {
    id: doc._id ? doc._id.toString() : doc.toString(),
    firstName: doc.firstName || "",
    lastName: doc.lastName || "",
    username: doc.username || "",
    avatarUrl: doc.avatarUrl || "",
    accountPrivacy: doc.accountPrivacy || "public",
  };
}

async function sendMessage(senderId, recipientId, text, senderUsername, file, options = {}) {
  const cleanText = text ? text.toString().trim() : "";
  const hasFile = !!file;

  if (!cleanText && !hasFile) {
    const err = new Error("Message vide");
    err.statusCode = 400;
    throw err;
  }

  let type = "text";
  let mediaUrl = "";
  let mediaMime = "";
  let audioDurationMs = options.audioDurationMs ?? null;

  if (hasFile) {
    mediaUrl = `/uploads/messages/${file.filename}`;
    mediaMime = file.mimetype || "";
    if (mediaMime.startsWith("image/")) {
      type = "image";
    } else if (mediaMime.startsWith("audio/")) {
      type = "audio";
    } else {
      const err = new Error("Type de media non supporte");
      err.statusCode = 400;
      throw err;
    }
  }

  const message = await PrivateMessage.create({
    sender: senderId,
    recipient: recipientId,
    text: cleanText,
    type,
    mediaUrl,
    mediaMime,
    audioDurationMs,
    replyTo: options.replyTo || null,
    storyImageUrl: options.storyImageUrl || "",
  });

  const populatedMsg = await PrivateMessage.findById(message._id)
    .populate("sender", "firstName lastName username avatarUrl")
    .populate("recipient", "firstName lastName username avatarUrl")
    .populate({
      path: "replyTo",
      populate: { path: "sender", select: "firstName lastName username avatarUrl" }
    });

  const publicMsg = populatedMsg.toPublic();

  // Real-time via socket
  sendToUser(recipientId, "new_private_message", publicMsg);

  // Also create a notification
  await notificationsService.createNotification({
    recipient: recipientId,
    sender: senderId,
    type: "message",
    text: `${senderUsername} vous a envoyé un message`,
  });

  return publicMsg;
}

async function getChatHistory(userId, otherUserId, limit = 50) {
  const messages = await PrivateMessage.find({
    $or: [
      { sender: userId, recipient: otherUserId },
      { sender: otherUserId, recipient: userId },
    ],
  })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate("sender", "firstName lastName username avatarUrl")
    .populate("recipient", "firstName lastName username avatarUrl")
    .populate({
      path: "replyTo",
      populate: { path: "sender", select: "firstName lastName username avatarUrl" }
    });

  return messages.reverse().map((m) => m.toPublic());
}

async function getConversations(userId) {
  const messages = await PrivateMessage.find({
    $or: [{ sender: userId }, { recipient: userId }],
  })
    .sort({ createdAt: -1 })
    .populate("sender", "firstName lastName username avatarUrl")
    .populate("recipient", "firstName lastName username avatarUrl");

  const unreadAgg = await PrivateMessage.aggregate([
    { $match: { recipient: userId, isRead: false } },
    { $group: { _id: "$sender", count: { $sum: 1 } } },
  ]);
  const unreadMap = new Map(
    unreadAgg.map((u) => [u._id.toString(), u.count])
  );

  const conversations = new Map();
  messages.forEach((m) => {
    const senderId = m.sender && m.sender._id ? m.sender._id.toString() : m.sender.toString();
    const recipientId = m.recipient && m.recipient._id ? m.recipient._id.toString() : m.recipient.toString();
    const otherUser = senderId === userId.toString() ? m.recipient : m.sender;
    const otherUserId = senderId === userId.toString() ? recipientId : senderId;
    if (!conversations.has(otherUserId)) {
      conversations.set(otherUserId, {
        user: normalizeUser(otherUser),
        lastMessage: m.toPublic(),
        unreadCount: unreadMap.get(otherUserId) || 0,
      });
    }
  });

  return Array.from(conversations.values());
}

async function markChatRead(userId, otherUserId) {
  const now = new Date();
  const result = await PrivateMessage.updateMany(
    { sender: otherUserId, recipient: userId, isRead: false },
    { isRead: true, readAt: now }
  );

  if (result.modifiedCount && result.modifiedCount > 0) {
    sendToUser(otherUserId, "private_messages_read", {
      readerId: userId.toString(),
      readAt: now,
    });
  }

  return result.modifiedCount || 0;
}

async function deleteMessageForAll(messageId, userId) {
  const message = await PrivateMessage.findById(messageId);
  if (!message) {
    const err = new Error("Message introuvable");
    err.statusCode = 404;
    throw err;
  }

  if (message.sender.toString() !== userId.toString()) {
    const err = new Error("Action non autorisee");
    err.statusCode = 403;
    throw err;
  }

  if (!message.deletedForAll) {
    message.deletedForAll = true;
    message.deletedAt = new Date();
    await message.save();
  }

  sendToUser(message.recipient, "private_message_deleted", {
    messageId: message._id.toString(),
  });
  sendToUser(message.sender, "private_message_deleted", {
    messageId: message._id.toString(),
  });

  return message;
}

async function editMessage(messageId, userId, newText) {
  const message = await PrivateMessage.findById(messageId);
  if (!message) {
    const err = new Error("Message introuvable");
    err.statusCode = 404;
    throw err;
  }

  if (message.sender.toString() !== userId.toString()) {
    const err = new Error("Action non autorisee");
    err.statusCode = 403;
    throw err;
  }

  if (message.deletedForAll) {
    const err = new Error("Message supprimé");
    err.statusCode = 400;
    throw err;
  }

  message.text = newText;
  message.isEdited = true;
  message.editedAt = new Date();
  await message.save();

  const populatedMsg = await PrivateMessage.findById(message._id)
    .populate("sender", "firstName lastName username avatarUrl")
    .populate("recipient", "firstName lastName username avatarUrl")
    .populate({
      path: "replyTo",
      populate: { path: "sender", select: "firstName lastName username avatarUrl" }
    });

  const publicMsg = populatedMsg.toPublic();

  sendToUser(message.recipient, "private_message_edited", publicMsg);
  sendToUser(message.sender, "private_message_edited", publicMsg);

  return publicMsg;
}

async function reactToMessage(messageId, userId, reactionType) {
  const message = await PrivateMessage.findById(messageId);
  if (!message) {
    const err = new Error("Message introuvable");
    err.statusCode = 404;
    throw err;
  }

  const existingReactionIndex = message.reactions.findIndex(
    (r) => r.userId.toString() === userId.toString() && r.reactionType === reactionType
  );

  if (existingReactionIndex > -1) {
    // Remove reaction if it exists
    message.reactions.splice(existingReactionIndex, 1);
  } else {
    // Add reaction
    message.reactions.push({ userId, reactionType });
  }

  await message.save();

  const populatedMsg = await PrivateMessage.findById(message._id)
    .populate("sender", "firstName lastName username avatarUrl")
    .populate("recipient", "firstName lastName username avatarUrl")
    .populate({
      path: "replyTo",
      populate: { path: "sender", select: "firstName lastName username avatarUrl" }
    });

  const publicMsg = populatedMsg.toPublic();

  sendToUser(message.recipient, "private_message_reacted", publicMsg);
  sendToUser(message.sender, "private_message_reacted", publicMsg);

  return publicMsg;
}

module.exports = {
  sendMessage,
  getChatHistory,
  getConversations,
  markChatRead,
  deleteMessageForAll,
  editMessage,
  reactToMessage,
};
