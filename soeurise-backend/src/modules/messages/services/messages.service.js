const PrivateMessage = require("../models/PrivateMessage");
const notificationsService = require("../../notifications/services/notifications.service");
const { sendToUser } = require("../../../utils/socket");

async function sendMessage(senderId, recipientId, text, senderUsername) {
  const message = await PrivateMessage.create({
    sender: senderId,
    recipient: recipientId,
    text,
  });

  const populatedMsg = await PrivateMessage.findById(message._id)
    .populate("sender", "firstName lastName username avatarUrl")
    .populate("recipient", "firstName lastName username avatarUrl");

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
    .populate("sender", "firstName lastName username avatarUrl");

  return messages.reverse().map((m) => m.toPublic());
}

async function getConversations(userId) {
    // This is a simplified version, it gets recent unique contacts
    const messages = await PrivateMessage.find({
        $or: [{ sender: userId }, { recipient: userId }]
    }).sort({ createdAt: -1 });

    const contacts = new Map();
    messages.forEach(m => {
        const otherId = m.sender.toString() === userId.toString() ? m.recipient.toString() : m.sender.toString();
        if (!contacts.has(otherId)) {
            contacts.set(otherId, m);
        }
    });

    // We would normally populate these, but for brevity:
    return Array.from(contacts.values());
}

module.exports = {
  sendMessage,
  getChatHistory,
  getConversations,
};
