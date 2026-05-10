const mongoose = require("mongoose");

const privateMessageSchema = new mongoose.Schema(
  {
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    text: {
      type: String,
      required: true,
      trim: true,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

privateMessageSchema.methods.toPublic = function () {
  return {
    id: this._id,
    sender: this.sender,
    recipient: this.recipient,
    text: this.text,
    isRead: this.isRead,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model("PrivateMessage", privateMessageSchema);
