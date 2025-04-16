const mongoose = require("mongoose");

const eventSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "Event title is required"],
      trim: true,
    },
    description: {
      type: String,
      required: [true, "Event description is required"],
      trim: true,
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Organization",
      required: [true, "Event must belong to an organization"],
    },
    startDate: {
      type: Date,
      required: [true, "Event start date is required"],
    },
    endDate: {
      type: Date,
      required: [true, "Event end date is required"],
    },
    location: {
      type: String,
      required: [true, "Event location is required"],
      trim: true,
    },
    attendees: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
        },
        status: {
          type: String,
          enum: ["attending", "maybe", "not_attending"],
          default: "attending",
        },
        registeredAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Event must have a creator"],
    },
    status: {
      type: String,
      enum: ["draft", "published", "cancelled", "completed"],
      default: "draft",
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
  }
);

// Add an attendee to the event
eventSchema.methods.addAttendee = async function (
  userId,
  status = "attending"
) {
  // Check if user is already an attendee
  const existingAttendee = this.attendees.find(
    (attendee) => attendee.user.toString() === userId.toString()
  );

  if (existingAttendee) {
    existingAttendee.status = status;
    await this.save();
    return this;
  }

  // Add the new attendee
  this.attendees.push({
    user: userId,
    status,
  });

  await this.save();
  return this;
};

// Remove an attendee from the event
eventSchema.methods.removeAttendee = async function (userId) {
  this.attendees = this.attendees.filter(
    (attendee) => attendee.user.toString() !== userId.toString()
  );

  await this.save();
  return this;
};

// Update an attendee's status
eventSchema.methods.updateAttendeeStatus = async function (userId, newStatus) {
  const attendee = this.attendees.find(
    (attendee) => attendee.user.toString() === userId.toString()
  );

  if (!attendee) {
    throw new Error("User is not an attendee of this event");
  }

  attendee.status = newStatus;
  await this.save();
  return this;
};

// Check if event is active (not cancelled or completed)
eventSchema.methods.isActive = function () {
  return this.status !== "cancelled" && this.status !== "completed";
};

// Check if event is in the past
eventSchema.methods.isPast = function () {
  return new Date() > this.endDate;
};

const Event = mongoose.model("Event", eventSchema);

module.exports = Event;
