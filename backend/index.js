// Required External Modules
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const morgan = require("morgan");
const helmet = require("helmet");
const compression = require("compression");
const cookieParser = require("cookie-parser");

// Required Internal Modules
const connectDB = require("./database/connect");
const errorHandler = require("./middleware/error_handler");

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

// Global Error Handler
app.use(errorHandler);

// Server Activation
const server = app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

// Connect to Database
connectDB();

// Graceful Shutdown Handlers
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

module.exports = app;
