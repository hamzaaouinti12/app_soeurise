const notificationsService = require("../services/notifications.service");

async function getNotifications(req, res, next) {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const result = await notificationsService.listNotifications(
      req.user._id,
      page,
      limit
    );
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function markRead(req, res, next) {
  try {
    await notificationsService.markAsRead(req.params.id, req.user._id);
    res.json({ success: true, message: "Notification marquée comme lue" });
  } catch (err) {
    next(err);
  }
}

async function markAllRead(req, res, next) {
  try {
    await notificationsService.markAllAsRead(req.user._id);
    res.json({ success: true, message: "Toutes les notifications marquées comme lues" });
  } catch (err) {
    next(err);
  }
}

async function getUnreadCount(req, res, next) {
  try {
    const count = await notificationsService.getUnreadCount(req.user._id);
    res.json({ success: true, data: { count } });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getNotifications,
  markRead,
  markAllRead,
  getUnreadCount,
};
