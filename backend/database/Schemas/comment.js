const mongoose = require("mongoose");

const commentSchema = new mongoose.Schema(
  {
    content: {
      type: String,
      required: [true, "Comment content is required"],
      trim: true,
      maxlength: [1000, "Comment cannot be more than 1000 characters"],
    },
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Comment author is required"],
    },
    event: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Event",
      required: [true, "Comment must be associated with an event"],
    },
    parentComment: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Comment",
      default: null,
    },
    likes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    isEdited: {
      type: Boolean,
      default: false,
    },
    editedAt: {
      type: Date,
      default: null,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Virtual for replies
commentSchema.virtual("replies", {
  ref: "Comment",
  localField: "_id",
  foreignField: "parentComment",
});

// Indexes
commentSchema.index({ event: 1, createdAt: -1 });
commentSchema.index({ parentComment: 1 });
commentSchema.index({ author: 1 });

// Static methods
commentSchema.statics.getCommentsForEvent = async function (eventId) {
  return this.find({ event: eventId, parentComment: null })
    .populate("author", "username profilePicture")
    .populate({
      path: "replies",
      populate: {
        path: "author",
        select: "username profilePicture",
      },
    })
    .sort({ createdAt: -1 });
};

commentSchema.statics.getRepliesForComment = async function (commentId) {
  return this.find({ parentComment: commentId })
    .populate("author", "username profilePicture")
    .sort({ createdAt: 1 });
};

commentSchema.statics.getCommentCountForEvent = async function (eventId) {
  return this.countDocuments({ event: eventId });
};

// Instance methods
commentSchema.methods.edit = async function (newContent) {
  this.content = newContent;
  this.isEdited = true;
  this.editedAt = new Date();
  return this.save();
};

commentSchema.methods.addLike = async function (userId) {
  if (!this.likes.includes(userId)) {
    this.likes.push(userId);
    return this.save();
  }
  return this;
};

commentSchema.methods.removeLike = async function (userId) {
  this.likes = this.likes.filter(
    (like) => like.toString() !== userId.toString()
  );
  return this.save();
};

commentSchema.methods.remove = async function () {
  // First, remove all replies to this comment
  await this.model("Comment").deleteMany({ parentComment: this._id });

  // Then remove the comment itself
  return this.deleteOne();
};

const Comment = mongoose.model("Comment", commentSchema);

module.exports = Comment;
