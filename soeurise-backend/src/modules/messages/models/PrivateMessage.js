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
    replyTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "PrivateMessage",
      default: null,
    },
    isEdited: {
      type: Boolean,
      default: false,
    },
    editedAt: {
      type: Date,
      default: null,
    },
    reactions: [
      {
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        reactionType: {
          type: String,
          required: true,
        },
      },
    ],
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
    storyImageUrl: {
      type: String,
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
    replyTo: this.replyTo,
    isEdited: this.isEdited,
    editedAt: this.editedAt,
    reactions: this.reactions,
    storyImageUrl: isDeleted ? "" : this.storyImageUrl,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model("PrivateMessage", privateMessageSchema);
