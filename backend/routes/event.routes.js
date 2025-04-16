const express = require("express");
const Event = require("../database/Schemas/event");
const Organization = require("../database/Schemas/organization");
const {
  authenticateToken,
  authorizeRole,
} = require("../middleware/auth.middleware");
const router = express.Router();

// Get all events (public)
router.get("/", async (req, res) => {
  try {
    const { organization, status, startDate, endDate } = req.query;
    const filter = {};

    if (organization) {
      filter.organization = organization;
    }

    if (status) {
      filter.status = status;
    }

    if (startDate && endDate) {
      filter.startDate = { $gte: new Date(startDate) };
      filter.endDate = { $lte: new Date(endDate) };
    }

    const events = await Event.find(filter)
      .populate("organization", "name logo")
      .populate("createdBy", "username profilePicture")
      .sort({ startDate: 1 });

    res.status(200).json({
      success: true,
      count: events.length,
      data: events,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get a single event by ID
router.get("/:id", async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate("organization", "name logo")
      .populate("createdBy", "username profilePicture")
      .populate("attendees.user", "username profilePicture");

    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }

    res.status(200).json({
      success: true,
      data: event,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Create a new event
router.post("/", authenticateToken, async (req, res) => {
  try {
    const { title, description, organization, startDate, endDate, location } =
      req.body;

    // Check if organization exists and user is a member
    const org = await Organization.findById(organization);
    if (!org) {
      return res.status(404).json({
        success: false,
        message: "Organization not found",
      });
    }

    // Check if user is a member of the organization
    const isMember = org.members.some(
      (member) => member.user.toString() === req.user.userId.toString()
    );

    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: "You must be a member of the organization to create events",
      });
    }

    const event = await Event.create({
      title,
      description,
      organization,
      startDate,
      endDate,
      location,
      createdBy: req.user.userId,
    });

    // Add the creator as an attendee
    await event.addAttendee(req.user.userId, "attending");

    // Add the event to the organization's events array
    org.events.push(event._id);
    await org.save();

    res.status(201).json({
      success: true,
      data: event,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Update an event
router.put("/:id", authenticateToken, async (req, res) => {
  try {
    const { title, description, startDate, endDate, location, status } =
      req.body;

    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }

    // Check if user is the creator or an officer of the organization
    const org = await Organization.findById(event.organization);
    const isCreator = event.createdBy.toString() === req.user.userId.toString();
    const isOfficer = org.members.some(
      (member) =>
        member.user.toString() === req.user.userId.toString() &&
        member.role === "officer"
    );

    if (!isCreator && !isOfficer) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to update this event",
      });
    }

    // Update fields
    if (title) event.title = title;
    if (description) event.description = description;
    if (startDate) event.startDate = startDate;
    if (endDate) event.endDate = endDate;
    if (location) event.location = location;
    if (status) event.status = status;

    await event.save();

    res.status(200).json({
      success: true,
      data: event,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Delete an event
router.delete("/:id", authenticateToken, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }

    // Check if user is the creator or an officer of the organization
    const org = await Organization.findById(event.organization);
    const isCreator = event.createdBy.toString() === req.user.userId.toString();
    const isOfficer = org.members.some(
      (member) =>
        member.user.toString() === req.user.userId.toString() &&
        member.role === "officer"
    );

    if (!isCreator && !isOfficer) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to delete this event",
      });
    }

    // Remove event from organization's events array
    org.events = org.events.filter(
      (eventId) => eventId.toString() !== event._id.toString()
    );
    await org.save();

    // Delete the event
    await event.remove();

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

// Register for an event
router.post("/:id/register", authenticateToken, async (req, res) => {
  try {
    const { status = "attending" } = req.body;
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }

    // Check if event is active
    if (!event.isActive()) {
      return res.status(400).json({
        success: false,
        message: "This event is no longer active",
      });
    }

    // Add user as attendee
    await event.addAttendee(req.user.userId, status);

    res.status(200).json({
      success: true,
      message: `Successfully registered for the event with status: ${status}`,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Update attendance status
router.put("/:id/attendance", authenticateToken, async (req, res) => {
  try {
    const { status } = req.body;
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }

    // Check if user is already an attendee
    const isAttendee = event.attendees.some(
      (attendee) => attendee.user.toString() === req.user.userId.toString()
    );

    if (!isAttendee) {
      return res.status(400).json({
        success: false,
        message: "You are not registered for this event",
      });
    }

    // Update attendance status
    await event.updateAttendeeStatus(req.user.userId, status);

    res.status(200).json({
      success: true,
      message: `Successfully updated attendance status to: ${status}`,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Get events for a specific organization
router.get("/organization/:orgId", async (req, res) => {
  try {
    const events = await Event.find({ organization: req.params.orgId })
      .populate("createdBy", "username profilePicture")
      .sort({ startDate: 1 });

    res.status(200).json({
      success: true,
      count: events.length,
      data: events,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get upcoming events
router.get("/upcoming", async (req, res) => {
  try {
    const events = await Event.find({
      startDate: { $gte: new Date() },
      status: { $in: ["draft", "published"] },
    })
      .populate("organization", "name logo")
      .populate("createdBy", "username profilePicture")
      .sort({ startDate: 1 })
      .limit(10);

    res.status(200).json({
      success: true,
      count: events.length,
      data: events,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
