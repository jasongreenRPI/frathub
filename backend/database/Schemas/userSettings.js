const mongoose = require("mongoose");

const userSettingsSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Settings must belong to a user"],
      unique: true,
    },
    notifications: {
      email: {
        eventInvites: {
          type: Boolean,
          default: true,
        },
        eventUpdates: {
          type: Boolean,
          default: true,
        },
        eventReminders: {
          type: Boolean,
          default: true,
        },
        orgInvites: {
          type: Boolean,
          default: true,
        },
        orgUpdates: {
          type: Boolean,
          default: true,
        },
        roleChanges: {
          type: Boolean,
          default: true,
        },
        systemAnnouncements: {
          type: Boolean,
          default: true,
        },
      },
      push: {
        eventInvites: {
          type: Boolean,
          default: true,
        },
        eventUpdates: {
          type: Boolean,
          default: true,
        },
        eventReminders: {
          type: Boolean,
          default: true,
        },
        orgInvites: {
          type: Boolean,
          default: true,
        },
        orgUpdates: {
          type: Boolean,
          default: true,
        },
        roleChanges: {
          type: Boolean,
          default: true,
        },
        systemAnnouncements: {
          type: Boolean,
          default: true,
        },
      },
      inApp: {
        eventInvites: {
          type: Boolean,
          default: true,
        },
        eventUpdates: {
          type: Boolean,
          default: true,
        },
        eventReminders: {
          type: Boolean,
          default: true,
        },
        orgInvites: {
          type: Boolean,
          default: true,
        },
        orgUpdates: {
          type: Boolean,
          default: true,
        },
        roleChanges: {
          type: Boolean,
          default: true,
        },
        systemAnnouncements: {
          type: Boolean,
          default: true,
        },
      },
    },
    privacy: {
      profileVisibility: {
        type: String,
        enum: ["public", "members", "private"],
        default: "public",
      },
      showEmail: {
        type: Boolean,
        default: false,
      },
      showPhone: {
        type: Boolean,
        default: false,
      },
      showBirthday: {
        type: Boolean,
        default: false,
      },
      showLocation: {
        type: Boolean,
        default: false,
      },
    },
    display: {
      theme: {
        type: String,
        enum: ["light", "dark", "system"],
        default: "system",
      },
      language: {
        type: String,
        default: "en",
      },
      timezone: {
        type: String,
        default: "UTC",
      },
      dateFormat: {
        type: String,
        enum: ["MM/DD/YYYY", "DD/MM/YYYY", "YYYY-MM-DD"],
        default: "MM/DD/YYYY",
      },
      timeFormat: {
        type: String,
        enum: ["12h", "24h"],
        default: "12h",
      },
    },
    calendar: {
      defaultView: {
        type: String,
        enum: ["day", "week", "month", "agenda"],
        default: "month",
      },
      showWeekends: {
        type: Boolean,
        default: true,
      },
      startWeekOn: {
        type: String,
        enum: ["sunday", "monday"],
        default: "sunday",
      },
      workingHours: {
        start: {
          type: String,
          default: "09:00",
        },
        end: {
          type: String,
          default: "17:00",
        },
      },
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

// Update notification settings
userSettingsSchema.methods.updateNotificationSettings = async function (
  category,
  channel,
  settings
) {
  if (this.notifications[category] && this.notifications[category][channel]) {
    Object.keys(settings).forEach((key) => {
      if (this.notifications[category][channel].hasOwnProperty(key)) {
        this.notifications[category][channel][key] = settings[key];
      }
    });
    await this.save();
  }
  return this;
};

// Update privacy settings
userSettingsSchema.methods.updatePrivacySettings = async function (settings) {
  Object.keys(settings).forEach((key) => {
    if (this.privacy.hasOwnProperty(key)) {
      this.privacy[key] = settings[key];
    }
  });
  await this.save();
  return this;
};

// Update display settings
userSettingsSchema.methods.updateDisplaySettings = async function (settings) {
  Object.keys(settings).forEach((key) => {
    if (this.display.hasOwnProperty(key)) {
      this.display[key] = settings[key];
    }
  });
  await this.save();
  return this;
};

// Update calendar settings
userSettingsSchema.methods.updateCalendarSettings = async function (settings) {
  Object.keys(settings).forEach((key) => {
    if (this.calendar.hasOwnProperty(key)) {
      this.calendar[key] = settings[key];
    }
  });
  await this.save();
  return this;
};

// Static method to get or create settings for a user
userSettingsSchema.statics.getOrCreateSettings = async function (userId) {
  let settings = await this.findOne({ user: userId });

  if (!settings) {
    settings = await this.create({ user: userId });
  }

  return settings;
};

const UserSettings = mongoose.model("UserSettings", userSettingsSchema);

module.exports = UserSettings;
