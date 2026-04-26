const Event = require("../models/Event");

/**
 * @desc    Get all events
 * @route   GET /api/events
 * @access  Public
 */
exports.getAllEvents = async (req, res, next) => {
  try {
    const events = await Event.find().sort({ dateTime: 1 });

    res.json({
      success: true,
      data: events,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create a new event
 * @route   POST /api/events
 * @access  Private/Admin
 */
exports.createEvent = async (req, res, next) => {
  try {
    const { title, dateTime, type, location, imageUrl } = req.body;

    const event = await Event.create({
      title,
      dateTime,
      type,
      location,
      imageUrl,
    });

    res.status(201).json({
      success: true,
      data: event,
    });
  } catch (error) {
    next(error);
  }
};
