const mongoose = require("mongoose");
const { MongoMemoryServer } = require("mongodb-memory-server");
const request = require("supertest");

// Set test environment before importing the app
process.env.NODE_ENV = "test";

// Import app after setting NODE_ENV to prevent automatic connection
const { app, server } = require("../index");
const User = require("../database/Schemas/user");
const Organization = require("../database/Schemas/organization");
const Queue = require("../database/Schemas/queue");

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

// Helper function to create a test user
const createTestUser = async (userData = {}, type = "user") => {
  let user;
  if (type === "user") {
    user = {
      email: "test@example.com",
      password: "password123",
      username: "testuser",
      firstName: "Test",
      lastName: "User",
      role: "user",
      ...userData,
    };
  } else if (type === "admin") {
    user = {
      email: "admin@example.com",
      password: "password123",
      username: "adminuser",
      firstName: "Admin",
      lastName: "User",
      role: "superuser",
      ...userData,
    };
  } else if (type === "officer") {
    user = {
      email: "officer@example.com",
      password: "password123",
      username: "officeruser",
      firstName: "Officer",
      lastName: "User",
      role: "officer",
      ...userData,
    };
  }

  // Ensure role is not overridden by userData
  const { role, ...restUserData } = userData;
  return await User.signUp(user.email, user.password, {
    username: user.username,
    firstName: user.firstName,
    lastName: user.lastName,
    role: user.role,
    ...restUserData,
  });
};

// Helper function to create a test organization
const createTestOrganization = async (orgData = {}) => {
  const defaultOrg = {
    name: "Test Organization",
    superUserId: null,
    key: "testkey123",
    ...orgData,
  };

  const { organization, hashKey } = await Organization.createOrganization(
    defaultOrg.name,
    defaultOrg.superUserId,
    defaultOrg.key
  );

  return { organization, hashKey };
};

// Helper function to get auth token
const getAuthToken = async (user) => {
  const response = await request(app).post("/api/auth/login").send({
    email: user.email,
    password: "password123",
  });
  return response.body.token;
};

module.exports = {
  createTestUser,
  createTestOrganization,
  getAuthToken,
  request,
  app,
};
