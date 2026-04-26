const Masterclass = require("../models/Masterclass");

/**
 * @desc    Get all masterclasses
 * @route   GET /api/masterclass
 * @access  Public
 */
exports.getAllMasterclasses = async (req, res, next) => {
  try {
    const masterclasses = await Masterclass.find().sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: masterclasses,
    });
  } catch (error) {
    next(error);
  }
};
