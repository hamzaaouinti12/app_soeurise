const mongoose = require("mongoose");

const groupMemberSchema = new mongoose.Schema(
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

        roleInGroup: {
            type: String,
            enum: ["owner", "moderator", "member"],
            default: "member",
        },

        status: {
            type: String,
            enum: ["pending", "active", "banned"],
            default: "pending",
        },

        joinedAt: {
            type: Date,
            default: null,
        },
    },
    { timestamps: true }
);

// Index unique: un user ne peut être membre qu'une seule fois par groupe
groupMemberSchema.index({ groupId: 1, userId: 1 }, { unique: true });

// Données publiques
groupMemberSchema.methods.toPublic = function () {
    return {
        id: this._id,
        groupId: this.groupId,
        userId: this.userId,
        roleInGroup: this.roleInGroup,
        status: this.status,
        joinedAt: this.joinedAt,
        createdAt: this.createdAt,
    };
};

module.exports = mongoose.model("GroupMember", groupMemberSchema);
