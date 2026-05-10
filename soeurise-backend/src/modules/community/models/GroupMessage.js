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
    return {
        id: this._id,
        groupId: this.groupId,
        senderId: this.senderId._id ? this.senderId._id : this.senderId,
        sender: this.senderId.username ? this.senderId.username : "Inconnu",
        senderAvatar: this.senderId.avatarUrl ? this.senderId.avatarUrl : "",
        text: this.text,
        timestamp: this.createdAt,
    };
};

module.exports = mongoose.model("GroupMessage", groupMessageSchema);
