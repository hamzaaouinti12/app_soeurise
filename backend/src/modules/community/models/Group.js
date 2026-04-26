const mongoose = require("mongoose");

const groupSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            unique: true,
            trim: true,
            minlength: 3,
            maxlength: 80,
        },
        description: {
            type: String,
            default: "",
            trim: true,
            maxlength: 500,
        },

        // Image du groupe (optionnelle)
        imageUrl: { type: String, default: "" },
        imageMime: { type: String, default: "" },

        // Visibilité et accès
        isPublic: { type: Boolean, default: true },
        requiresSubscription: { type: Boolean, default: false },

        // Créateur du groupe
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
    },
    { timestamps: true }
);

// Données publiques
groupSchema.methods.toPublic = function () {
    return {
        id: this._id,
        name: this.name,
        description: this.description,
        imageUrl: this.imageUrl,
        isPublic: this.isPublic,
        requiresSubscription: this.requiresSubscription,
        createdBy: this.createdBy,
        createdAt: this.createdAt,
        updatedAt: this.updatedAt,
    };
};

module.exports = mongoose.model("Group", groupSchema);
