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
    type: {
      type: String,
      enum: ["text", "image", "audio"],
      default: "text",
    },
    text: {
      type: String,
      default: "",
      trim: true,
    },
    mediaUrl: {
      type: String,
      default: "",
    },
    mediaMime: {
      type: String,
      default: "",
    },
    audioDurationMs: {
      type: Number,
      default: null,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    readAt: {
      type: Date,
      default: null,
    },
    deletedForAll: {
      type: Boolean,
      default: false,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

privateMessageSchema.methods.toPublic = function () {
  const isDeleted = this.deletedForAll === true;
  return {
    id: this._id,
    sender: this.sender,
    recipient: this.recipient,
    senderId: this.sender && this.sender._id ? this.sender._id : this.sender,
    recipientId: this.recipient && this.recipient._id ? this.recipient._id : this.recipient,
    type: this.type,
    text: isDeleted ? "" : this.text,
    mediaUrl: isDeleted ? "" : this.mediaUrl,
    mediaMime: this.mediaMime,
    audioDurationMs: this.audioDurationMs,
    isRead: this.isRead,
    readAt: this.readAt,
    deletedForAll: this.deletedForAll,
    deletedAt: this.deletedAt,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model("PrivateMessage", privateMessageSchema);
