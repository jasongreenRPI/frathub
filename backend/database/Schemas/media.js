const mongoose = require("mongoose");

const mediaSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "Media title is required"],
      trim: true,
    },
    description: {
      type: String,
      trim: true,
      default: "",
    },
    type: {
      type: String,
      enum: ["image", "video", "document", "audio"],
      required: [true, "Media type is required"],
    },
    url: {
      type: String,
      required: [true, "Media URL is required"],
      trim: true,
    },
    thumbnailUrl: {
      type: String,
      trim: true,
      default: null,
    },
    size: {
      type: Number,
      required: [true, "Media size is required"],
    },
    mimeType: {
      type: String,
      required: [true, "Media MIME type is required"],
    },
    uploadedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Media must have an uploader"],
    },
    relatedEntity: {
      entityType: {
        type: String,
        enum: ["Event", "Organization"],
        required: [true, "Media must be associated with an entity"],
      },
      entityId: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: "relatedEntity.entityType",
        required: [true, "Media must be associated with an entity ID"],
      },
    },
    isPublic: {
      type: Boolean,
      default: true,
    },
    tags: [
      {
        type: String,
        trim: true,
      },
    ],
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
  }
);

// Index for faster queries
mediaSchema.index({
  "relatedEntity.entityType": 1,
  "relatedEntity.entityId": 1,
});
mediaSchema.index({ uploadedBy: 1 });
mediaSchema.index({ tags: 1 });

// Update media details
mediaSchema.methods.updateDetails = async function (updates) {
  const allowedUpdates = ["title", "description", "isPublic", "tags"];

  Object.keys(updates).forEach((update) => {
    if (allowedUpdates.includes(update)) {
      this[update] = updates[update];
    }
  });

  await this.save();
  return this;
};

// Static method to get all media for an event
mediaSchema.statics.getMediaForEvent = async function (eventId) {
  return await this.find({
    "relatedEntity.entityType": "Event",
    "relatedEntity.entityId": eventId,
  })
    .populate("uploadedBy", "username profilePicture")
    .sort({ createdAt: -1 });
};

// Static method to get all media for an organization
mediaSchema.statics.getMediaForOrganization = async function (orgId) {
  return await this.find({
    "relatedEntity.entityType": "Organization",
    "relatedEntity.entityId": orgId,
  })
    .populate("uploadedBy", "username profilePicture")
    .sort({ createdAt: -1 });
};

// Static method to get media by type
mediaSchema.statics.getMediaByType = async function (
  entityType,
  entityId,
  mediaType
) {
  return await this.find({
    "relatedEntity.entityType": entityType,
    "relatedEntity.entityId": entityId,
    type: mediaType,
  })
    .populate("uploadedBy", "username profilePicture")
    .sort({ createdAt: -1 });
};

// Static method to search media by tags
mediaSchema.statics.searchByTags = async function (entityType, entityId, tags) {
  return await this.find({
    "relatedEntity.entityType": entityType,
    "relatedEntity.entityId": entityId,
    tags: { $in: tags },
  })
    .populate("uploadedBy", "username profilePicture")
    .sort({ createdAt: -1 });
};

const Media = mongoose.model("Media", mediaSchema);

module.exports = Media;
