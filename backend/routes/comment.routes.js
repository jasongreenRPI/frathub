const express = require("express");
const Comment = require("../database/Schemas/comment");
const {
  authenticateToken,
  authorizeRole,
} = require("../middleware/auth.middleware");
const router = express.Router();

// Get all comments for an event
router.get("/event/:eventId", authenticateToken, async (req, res) => {
  try {
    const comments = await Comment.getCommentsForEvent(req.params.eventId);

    res.status(200).json({
      success: true,
      count: comments.length,
      data: comments,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get replies for a specific comment
router.get("/:commentId/replies", authenticateToken, async (req, res) => {
  try {
    const replies = await Comment.getRepliesForComment(req.params.commentId);

    res.status(200).json({
      success: true,
      count: replies.length,
      data: replies,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get comment count for an event
router.get("/event/:eventId/count", authenticateToken, async (req, res) => {
  try {
    const count = await Comment.getCommentCountForEvent(req.params.eventId);

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

// Create a new comment
router.post("/", authenticateToken, async (req, res) => {
  try {
    const { content, event, parentComment } = req.body;

    const comment = await Comment.create({
      content,
      author: req.user.userId,
      event,
      parentComment,
    });

    res.status(201).json({
      success: true,
      data: comment,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Update a comment
router.put("/:id", authenticateToken, async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    // Check if the comment belongs to the user
    if (comment.author.toString() !== req.user.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to update this comment",
      });
    }

    const { content } = req.body;
    await comment.edit(content);

    res.status(200).json({
      success: true,
      data: comment,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Delete a comment
router.delete("/:id", authenticateToken, async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    // Check if the comment belongs to the user or if the user is an admin
    if (
      comment.author.toString() !== req.user.userId.toString() &&
      !req.user.roles.includes("admin")
    ) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to delete this comment",
      });
    }

    await comment.remove();

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

// Like a comment
router.post("/:id/like", authenticateToken, async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    await comment.addLike(req.user.userId);

    res.status(200).json({
      success: true,
      data: comment,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Unlike a comment
router.delete("/:id/like", authenticateToken, async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    await comment.removeLike(req.user.userId);

    res.status(200).json({
      success: true,
      data: comment,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router; 