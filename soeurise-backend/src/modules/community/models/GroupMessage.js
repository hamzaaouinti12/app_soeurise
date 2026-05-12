const mongoose = require("mongoose");

const groupMessageSchema = new mongoose.Schema(
    {
        groupId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Group",
            required: true,
            index: true,
        },
        senderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        text: {
            type: String,
            required: true,
            trim: true,
            maxlength: 2000,
        },
        replyTo: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "GroupMessage",
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
        // Liste des userId ayant vu ce message
        seenBy: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: "User",
            },
        ],
    },
    { timestamps: true }
);

// Method to return public data
groupMessageSchema.methods.toPublic = function () {
    const senderDoc = this.senderId && this.senderId._id ? this.senderId : null;
    const senderId = senderDoc ? senderDoc._id.toString() : this.senderId.toString();
    const firstName = senderDoc?.firstName || "";
    const lastName = senderDoc?.lastName || "";
    const username = senderDoc?.username || "";
    const displayName = `${firstName} ${lastName}`.trim() || username || "Inconnu";

    return {
        id: this._id,
        groupId: this.groupId,
        senderId,
        sender: displayName,
        senderAvatar: senderDoc?.avatarUrl || "",
        text: this.text,
        timestamp: this.createdAt,
        seenBy: (this.seenBy || []).map((id) => id.toString()),
        seenCount: (this.seenBy || []).length,
        replyTo: this.replyTo,
        isEdited: this.isEdited,
        editedAt: this.editedAt,
        reactions: this.reactions,
    };
};

module.exports = mongoose.model("GroupMessage", groupMessageSchema);

