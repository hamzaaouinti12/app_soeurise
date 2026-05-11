const mongoose = require("mongoose");

const reportSchema = new mongoose.Schema(
  {
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    targetUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    targetPost: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Post",
      default: null,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    details: {
      type: String,
      default: "",
      trim: true,
      maxlength: 1000,
    },
    status: {
      type: String,
      enum: ["open", "closed"],
      default: "open",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Report", reportSchema);
