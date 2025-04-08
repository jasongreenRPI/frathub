const mongoose = require("mongoose");
const { MongoMemoryServer } = require("mongodb-memory-server");
const request = require("supertest");

// Set test environment before importing the app
process.env.NODE_ENV = "test";

// Import app after setting NODE_ENV to prevent automatic connection
const { app, server } = require("../index");
let mongoServer;

// Connect to the in-memory database
beforeAll(async () => {
  // Close any existing connection
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }

  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();
  await mongoose.connect(mongoUri);
});

// Clear all data between tests
afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany();
  }
});

// Close database connection and stop server
afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
  if (server) {
    server.close();
  }
});

const userData = {
  email: "test@test.com",
  password: "password123",
  username: "testuser",
  firstName: "Test",
  lastName: "User",
  role: "user",
};

const adminData = {
  email: "admin@test.com",
  password: "password123",
  username: "adminuser",
  firstName: "Admin",
  lastName: "User",
  role: "admin",
};

const officerData = {
  email: "admin@test.com",
  password: "password123",
  username: "officeruser",
  firstName: "Officer",
  lastName: "User",
  role: "officer",
};       

module.exports = {
  app,
  server,
  request,
};
