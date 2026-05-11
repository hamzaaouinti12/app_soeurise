const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    firstName: { type: String, required: true, trim: true, minlength: 2, maxlength: 50 },
    lastName: { type: String, required: true, trim: true, minlength: 2, maxlength: 50 },

    username: { type: String, required: true, unique: true, trim: true, minlength: 3, maxlength: 30 },

    email: { type: String, required: true, unique: true, lowercase: true, trim: true },

    passwordHash: { type: String, required: true },

    // Avatar (image de profil)
    avatarUrl: { type: String, default: "" },
    avatarMime: { type: String, default: "" },

    role: { type: String, enum: ["user", "admin", "staff"], default: "user" },
    isActive: { type: Boolean, default: true },

    // Compte public : tout le monde peut voir vos posts hors communautés et suivre directement.
    // Compte privé : vos posts hors communautés sont visibles uniquement par vos abonnés acceptés ;
    // les autres envoient une demande à accepter/refuser.
    accountPrivacy: {
      type: String,
      enum: ["public", "private"],
      default: "public",
      index: true,
    },

    // Demandes d'abonnement reçues (utilisateurs qui veulent suivre ce compte privé)
    pendingFollowRequests: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    // Following / Followers
    following: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    followers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    // Publications sauvegardees
    savedPosts: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Post",
      },
    ],

    // Utilisateurs bloqués
    blockedUsers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
  },
  { timestamps: true }
);

// Public data (jamais renvoyer passwordHash)
userSchema.methods.toPublic = function () {
  return {
    id: this._id,
    firstName: this.firstName,
    lastName: this.lastName,
    username: this.username,
    email: this.email,
    avatarUrl: this.avatarUrl,
    role: this.role,
    isActive: this.isActive,
    accountPrivacy: this.accountPrivacy || "public",
    createdAt: this.createdAt,
    followingCount: this.following ? this.following.length : 0,
    followersCount: this.followers ? this.followers.length : 0,
    pendingIncomingFollowRequestsCount: this.pendingFollowRequests
      ? this.pendingFollowRequests.length
      : 0,
  };
};

module.exports = mongoose.model("User", userSchema);
