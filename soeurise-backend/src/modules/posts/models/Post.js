const mongoose = require("mongoose");

const postSchema = new mongoose.Schema(
  {
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    hashtags: [
      {
        type: String,
        index: true,
      },
    ],
    image: {
      type: String,
      default: "",
    },
    communityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Group",
      default: null,
    },
    likesCount: {
      type: Number,
      default: 0,
    },
    commentsCount: {
      type: Number,
      default: 0,
    },
    sharesCount: {
      type: Number,
      default: 0,
    },
    commentsDisabled: {
      type: Boolean,
      default: false,
    },
    isPinned: {
      type: Boolean,
      default: false,
    },
    likedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    comments: [
      {
        author: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        content: {
          type: String,
          required: true,
        },
        createdAt: {
          type: Date,
          default: Date.now,
        },
        isHidden: {
          type: Boolean,
          default: false,
        },
        isPinned: {
          type: Boolean,
          default: false,
        },
        likes: [
          {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
          },
        ],
        replies: [
          {
            author: {
              type: mongoose.Schema.Types.ObjectId,
              ref: "User",
              required: true,
            },
            replyTo: {
              type: mongoose.Schema.Types.ObjectId,
              default: null,
            },
            content: {
              type: String,
              required: true,
            },
            createdAt: {
              type: Date,
              default: Date.now,
            },
            isHidden: {
              type: Boolean,
              default: false,
            },
            likes: [
              {
                type: mongoose.Schema.Types.ObjectId,
                ref: "User",
              },
            ],
          },
        ],
      },
    ],
  },
  {
    timestamps: true,
  }
);

// Virtual for checking if the current user liked the post
postSchema.virtual("isLiked").get(function () {
  if (this._currentUser && this.likedBy) {
    return this.likedBy.includes(this._currentUser._id);
  }
  return false;
});

postSchema.virtual("isSaved").get(function () {
  if (this._currentUser && Array.isArray(this._currentUser.savedPosts)) {
    const pid = this._id.toString();
    return this._currentUser.savedPosts.some((id) => id.toString() === pid);
  }
  return false;
});

// Ensure virtuals are included when converting to JSON
postSchema.set("toJSON", { virtuals: true });
postSchema.set("toObject", { virtuals: true });

module.exports = mongoose.model("Post", postSchema);
