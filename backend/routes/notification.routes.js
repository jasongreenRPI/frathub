const express = require("express");
const Notification = require("../database/Schemas/notification");
const {
  authenticateToken,
  authorizeRole,
} = require("../middleware/auth.middleware");
const router = express.Router();

// Get all notifications for the authenticated user
router.get("/", authenticateToken, async (req, res) => {
  try {
    const { read, type } = req.query;
    const filter = { recipient: req.user.userId };

    if (read !== undefined) {
      filter.read = read === "true";
    }

    if (type) {
      filter.type = type;
    }

    const notifications = await Notification.find(filter)
      .populate("relatedEntity.entityId")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: notifications.length,
      data: notifications,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get unread notifications count
router.get("/unread-count", authenticateToken, async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      recipient: req.user.userId,
      read: false,
    });

    res.status(200).json({
      success: true,
      count,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get a single notification
router.get("/:id", authenticateToken, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id).populate(
      "relatedEntity.entityId"
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Notification not found",
      });
    }

    // Check if the notification belongs to the user
    if (notification.recipient.toString() !== req.user.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to view this notification",
      });
    }

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Mark a notification as read
router.put("/:id/read", authenticateToken, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Notification not found",
      });
    }

    // Check if the notification belongs to the user
    if (notification.recipient.toString() !== req.user.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to update this notification",
      });
    }

    await notification.markAsRead();

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Mark a notification as unread
router.put("/:id/unread", authenticateToken, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Notification not found",
      });
    }

    // Check if the notification belongs to the user
    if (notification.recipient.toString() !== req.user.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to update this notification",
      });
    }

    await notification.markAsUnread();

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Mark all notifications as read
router.put("/mark-all-read", authenticateToken, async (req, res) => {
  try {
    await Notification.markAllAsRead(req.user.userId);

    res.status(200).json({
      success: true,
      message: "All notifications marked as read",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Delete a notification
router.delete("/:id", authenticateToken, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Notification not found",
      });
    }

    // Check if the notification belongs to the user
    if (notification.recipient.toString() !== req.user.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to delete this notification",
      });
    }

    await notification.remove();

    res.status(200).json({
      success: true,
      data: {},
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Create a notification (admin only)
router.post(
  "/",
  authenticateToken,
  authorizeRole(["admin"]),
  async (req, res) => {
    try {
      const { recipient, type, title, message, relatedEntity } = req.body;

      const notification = await Notification.create({
        recipient,
        type,
        title,
        message,
        relatedEntity,
      });

      res.status(201).json({
        success: true,
        data: notification,
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// Create an event notification
router.post("/event", authenticateToken, async (req, res) => {
  try {
    const { recipientId, eventId, type, title, message } = req.body;

    const notification = await Notification.createEventNotification(
      recipientId,
      eventId,
      type,
      title,
      message
    );

    res.status(201).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Create an organization notification
router.post("/organization", authenticateToken, async (req, res) => {
  try {
    const { recipientId, orgId, type, title, message } = req.body;

    const notification = await Notification.createOrgNotification(
      recipientId,
      orgId,
      type,
      title,
      message
    );

    res.status(201).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
