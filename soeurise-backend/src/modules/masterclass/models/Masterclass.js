const mongoose = require("mongoose");

const masterclassSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    instructorName: {
      type: String,
      required: true,
    },
    videoUrl: {
      type: String,
      required: true,
    },
    thumbnailUrl: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
    collection: "masterclasses",
  }
);

module.exports = mongoose.model("Masterclass", masterclassSchema);
