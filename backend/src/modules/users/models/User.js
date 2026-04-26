const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    firstName: { type: String, required: true, trim: true, minlength: 2, maxlength: 50 },
    lastName: { type: String, required: true, trim: true, minlength: 2, maxlength: 50 },

    username: { type: String, required: true, unique: true, trim: true, minlength: 3, maxlength: 30 },

    email: { type: String, required: true, unique: true, lowercase: true, trim: true },

    passwordHash: { type: String, required: true },

    // ✅ Avatar (image de profil)
    avatarUrl: { type: String, default: "" },   // ex: /uploads/avatars/avatar_123.png
    avatarMime: { type: String, default: "" },  // ex: image/png

    role: { type: String, enum: ["user", "admin", "staff"], default: "user" },
    isActive: { type: Boolean, default: true },
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

    // ✅ on expose seulement l’URL de l’avatar
    avatarUrl: this.avatarUrl,

    role: this.role,
    isActive: this.isActive,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model("User", userSchema);
