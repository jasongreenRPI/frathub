const mongoose = require("mongoose");

const queueSchema = mongoose.Schema({
  orgId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Organization",
  },
  status: {
    type: String,
    enum: ["active", "paused", "closed", "maintenance"],
    default: "closed",
  },
  openToOutside: {
    type: Boolean,
    default: false,
  },

  // After you implement rides make an array of Active rides, set a max size
});

queueSchema.index({ orgId: 1 });

const Queue = mongoose.model("Queue", queueSchema, "Queue");
module.exports = Queue;
