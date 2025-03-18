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
  server.close();
});

// Helper function to create a test user
const createTestUser = async (userData = {}) => {
  const defaultUser = {
    email: "test@example.com",
    password: "password123",
    username: "testuser",
    firstName: "Test",
    lastName: "User",
    role: "user",
    ...userData,
  };

  return await User.signUp(defaultUser.email, defaultUser.password, {
    username: defaultUser.username,
    firstName: defaultUser.firstName,
    lastName: defaultUser.lastName,
    role: defaultUser.role,
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
