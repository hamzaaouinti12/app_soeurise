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
    };
};

module.exports = mongoose.model("GroupMessage", groupMessageSchema);
