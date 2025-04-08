// Required External Modules
const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const helmet = require("helmet");
const compression = require("compression");
const cookieParser = require("cookie-parser");
const jwt = require("jsonwebtoken");

// Required Internal Modules
const connectDB = require("./database/connect");
const errorHandler = require("./middleware/error_handler");

// Import Routes
const authRoutes = require("./routes/auth.routes");
const organizationRoutes = require("./routes/organization.routes");
const userRoutes = require("./routes/user.routes");

// Load Environment Variables
require("dotenv").config();

// App Variables
const app = express();
const PORT = process.env.PORT || 8080;

// Middleware Stack
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use(cors()); // Enable CORS
app.use(helmet()); // Security headers
app.use(compression()); // Compress responses
app.use(cookieParser()); // Parse cookies
app.use(morgan("dev")); // HTTP request logger

// Health Check Route
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

app.get("/generate-token", (req, res) => {
  const token = jwt.sign(
    { userId: "67ddb62ec117de158c7e5f68", expiresIn: "24h" },
    process.env.JWT_SECRET
  );
  res.status(200).json({ token });
});

// API Routes
app.use("/api/auth", authRoutes);
app.use("/api/organizations", organizationRoutes);
app.use("/api/users", userRoutes);

// Global Error Handler
app.use(errorHandler);

// Server Activation
let server;
if (process.env.NODE_ENV !== "test") {
  server = app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

// Connect to Database
if (process.env.NODE_ENV !== "test") {
  connectDB();
}

// Graceful Shutdown Handlers
if (process.env.NODE_ENV !== "test") {
  process.on("unhandledRejection", (err) => {
    console.log("UNHANDLED REJECTION! 💥 Shutting down...");
    console.log(err.name, err.message);
    server.close(() => {
      process.exit(1);
    });
  });

  process.on("SIGTERM", () => {
    console.log("👋 SIGTERM RECEIVED. Shutting down gracefully");
    server.close(() => {
      console.log("💥 Process terminated!");
    });
  });
}

module.exports = { app, server };

// eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2N2Q4NzY4NDgyODYxY2MwMzdmZTFmY2IiLCJlbWFpbCI6ImZyYXRodWJAZ21haWwuY29tIiwicm9sZSI6ImFkbWluIiwidXNlcm5hbWUiOiJhZG1pbnVzZXIiLCJpYXQiOjE3NDIyMzkzNjQsImV4cCI6MTc0MjMyNTc2NH0.oE48bmIL6XrJsSShHvrSdV52JALGJ_h4ssLnyQmNfsI
