const Notification = require("../models/Notification");
const { sendToUser } = require("../../../utils/socket");
const User = require("../../users/models/User");

/**
 * Create and send a notification
 */
async function createNotification({
  recipient,
  sender,
  type,
  post = null,
  comment = null,
  group = null,
  text,
}) {
  try {
    // 1. Save to DB
    const notification = await Notification.create({
      recipient,
      sender,
      type,
      post,
      comment,
      group,
      text,
    });

    // 2. Populate sender info for the socket event
    const populatedNotif = await Notification.findById(notification._id)
      .populate("sender", "firstName lastName username avatarUrl")
      .populate("post", "content image")
      .populate("group", "name imageUrl");

    // 3. Emit real-time if recipient is online
    sendToUser(recipient, "new_notification", populatedNotif);

    return populatedNotif;
  } catch (error) {
    console.error("Error creating notification:", error);
    // Don't throw, we don't want to break the main action (like/comment) if notification fails
  }
}

/**
 * List notifications for a user
 */
async function listNotifications(userId, page = 1, limit = 20) {
  const skip = (page - 1) * limit;
  const notifications = await Notification.find({ recipient: userId })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate("sender", "firstName lastName username avatarUrl")
    .populate("post", "content image")
    .populate("group", "name imageUrl");

  const total = await Notification.countDocuments({ recipient: userId });

  return {
    notifications,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    },
  };
}

/**
 * Mark as read
 */
async function markAsRead(notificationId, userId) {
  return Notification.findOneAndUpdate(
    { _id: notificationId, recipient: userId },
    { isRead: true },
    { new: true }
  );
}

/**
 * Mark all as read
 */
async function markAllAsRead(userId) {
  return Notification.updateMany(
    { recipient: userId, isRead: false },
    { isRead: true }
  );
}

/**
 * Get unread count
 */
async function getUnreadCount(userId) {
  return Notification.countDocuments({ recipient: userId, isRead: false });
}

module.exports = {
  createNotification,
  listNotifications,
  markAsRead,
  markAllAsRead,
  getUnreadCount,
};
