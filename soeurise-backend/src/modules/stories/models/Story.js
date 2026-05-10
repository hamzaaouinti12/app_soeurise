const mongoose = require("mongoose");

const reactionTypes = ["❤️", "🔥", "👍", "👏", "😮"];

const storySchema = new mongoose.Schema(
  {
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    mediaUrl: {
      type: String,
      required: true,
    },
    mediaType: {
      type: String,
      enum: ["image", "video"],
      required: true,
    },
    caption: {
      type: String,
      default: "",
      trim: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      default: () => new Date(Date.now() + 24 * 60 * 60 * 1000),
      index: true,
    },
    views: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        viewedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    reactions: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        type: {
          type: String,
          enum: reactionTypes,
          required: true,
        },
        reactedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
  },
  {
    timestamps: true,
  }
);

storySchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

storySchema.virtual("viewsCount").get(function () {
  return this.views ? this.views.length : 0;
});

storySchema.virtual("reactionCounts").get(function () {
  const counts = {};
  if (!Array.isArray(this.reactions)) return counts;
  this.reactions.forEach((reaction) => {
    counts[reaction.type] = (counts[reaction.type] || 0) + 1;
  });
  return counts;
});

storySchema.set("toJSON", { virtuals: true });
storySchema.set("toObject", { virtuals: true });

module.exports = mongoose.model("Story", storySchema);
