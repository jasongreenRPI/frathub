const express = require("express");
const User = require("../database/Schemas/user");
const {
  authenticateToken,
  authorizeRole,
} = require("../middleware/auth.middleware");
const router = express.Router();

// Get user profile (own profile)
router.get("/profile", authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get all users (admin only)
router.get(
  "/",
  authenticateToken,
  authorizeRole(["superuser", "admin"]),
  async (req, res) => {
    try {
      const users = await User.find().select("-password");

      res.status(200).json({
        success: true,
        count: users.length,
        data: users,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// Get user by ID (admin or same organization members)
router.get("/:id", authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        data: "User not found",
      });
    }

    // Check if requesting user has permission (superuser or same org)
    if (
      req.user.role !== "superuser" &&
      user.orgId &&
      req.user.orgId &&
      user.orgId.toString() !== req.user.orgId.toString()
    ) {
      return res.status(403).json({
        success: false,
        data: "Access denied. You can only view users in your organization.",
      });
    }

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      data: error.message,
    });
  }
});

// Update user (own profile)
router.put("/profile", authenticateToken, async (req, res) => {
  // Fields that users are allowed to update
  const allowedUpdates = ["firstName", "lastName", "username"];
  const updates = Object.keys(req.body);

  // Check if updates are allowed
  const isValidOperation = updates.every((update) =>
    allowedUpdates.includes(update)
  );

  if (!isValidOperation) {
    return res.status(400).json({
      success: false,
      message: "Invalid updates!",
    });
  }

  try {
    const user = await User.findById(req.user.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Apply updates
    updates.forEach((update) => (user[update] = req.body[update]));
    await user.save();

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Update user role (admin only)
router.patch(
  "/:id/role",
  authenticateToken,
  authorizeRole(["superuser", "admin"]),
  async (req, res) => {
    try {
      const { role } = req.body;

      if (!role || !["user", "officer", "superuser", "guest"].includes(role)) {
        return res.status(400).json({
          success: false,
          message: "Invalid role specified",
        });
      }

      const user = await User.findByIdAndUpdate(
        req.params.id,
        { role },
        { new: true, runValidators: true }
      ).select("-password");

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// Delete user (admin only)
router.delete(
  "/:id",
  authenticateToken,
  authorizeRole(["superuser", "admin"]),
  async (req, res) => {
    try {
      const user = await User.findByIdAndDelete(req.params.id);

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }

      res.status(200).json({
        success: true,
        message: "User deleted successfully",
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
);

module.exports = router;
