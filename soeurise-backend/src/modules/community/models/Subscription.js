const mongoose = require("mongoose");

const subscriptionSchema = new mongoose.Schema(
    {
        groupId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Group",
            required: true,
        },
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },

        plan: {
            type: String,
            enum: ["free", "premium", "member"],
            default: "free",
        },

        status: {
            type: String,
            enum: ["active", "inactive"],
            default: "active",
        },

        startedAt: {
            type: Date,
            default: Date.now,
        },
        endedAt: {
            type: Date,
            default: null,
        },
    },
    { timestamps: true }
);

// Index unique: une seule subscription par user par groupe
subscriptionSchema.index({ groupId: 1, userId: 1 }, { unique: true });

// Données publiques
subscriptionSchema.methods.toPublic = function () {
    return {
        id: this._id,
        groupId: this.groupId,
        userId: this.userId,
        plan: this.plan,
        status: this.status,
        startedAt: this.startedAt,
        endedAt: this.endedAt,
        createdAt: this.createdAt,
    };
};

module.exports = mongoose.model("Subscription", subscriptionSchema);
