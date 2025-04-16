const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Notification must have a recipient"],
    },
    type: {
      type: String,
      enum: [
        "event_invite",
        "event_update",
        "event_reminder",
        "org_invite",
        "org_update",
        "role_change",
        "system",
      ],
      required: [true, "Notification type is required"],
    },
    title: {
      type: String,
      required: [true, "Notification title is required"],
      trim: true,
    },
    message: {
      type: String,
      required: [true, "Notification message is required"],
      trim: true,
    },
    relatedEntity: {
      entityType: {
        type: String,
        enum: ["Event", "Organization", "User", "System"],
      },
      entityId: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: "relatedEntity.entityType",
      },
    },
    read: {
      type: Boolean,
      default: false,
    },
    readAt: {
      type: Date,
      default: null,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    expiresAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster queries
notificationSchema.index({ recipient: 1, read: 1 });
notificationSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: 30 * 24 * 60 * 60 }
); // Auto-delete after 30 days

// Mark notification as read
notificationSchema.methods.markAsRead = async function () {
  this.read = true;
  this.readAt = new Date();
  await this.save();
  return this;
};

// Mark notification as unread
notificationSchema.methods.markAsUnread = async function () {
  this.read = false;
  this.readAt = null;
  await this.save();
  return this;
};

// Static method to create event-related notifications
notificationSchema.statics.createEventNotification = async function (
  recipientId,
  eventId,
  type,
  title,
  message
) {
  return await this.create({
    recipient: recipientId,
    type,
    title,
    message,
    relatedEntity: {
      entityType: "Event",
      entityId: eventId,
    },
  });
};

// Static method to create organization-related notifications
notificationSchema.statics.createOrgNotification = async function (
  recipientId,
  orgId,
  type,
  title,
  message
) {
  return await this.create({
    recipient: recipientId,
    type,
    title,
    message,
    relatedEntity: {
      entityType: "Organization",
      entityId: orgId,
    },
  });
};

// Static method to get unread notifications for a user
notificationSchema.statics.getUnreadForUser = async function (userId) {
  return await this.find({
    recipient: userId,
    read: false,
  })
    .sort({ createdAt: -1 })
    .populate("relatedEntity.entityId");
};

// Static method to mark all notifications as read for a user
notificationSchema.statics.markAllAsRead = async function (userId) {
  return await this.updateMany(
    { recipient: userId, read: false },
    { $set: { read: true, readAt: new Date() } }
  );
};

const Notification = mongoose.model("Notification", notificationSchema);

module.exports = Notification;
