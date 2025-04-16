const mongoose = require("mongoose");
const { MongoMemoryServer } = require("mongodb-memory-server");
const request = require("supertest");
const app = require("../index");
const User = require("../database/Schemas/user");
const Organization = require("../database/Schemas/organization");

// Set test environment before importing the app
process.env.NODE_ENV = "test";

// Import app after setting NODE_ENV to prevent automatic connection
const { server } = require("../index");
let mongoServer;

// Mock external services
jest.mock("../utils/email", () => ({
  sendEmail: jest.fn().mockResolvedValue(true),
  sendPasswordResetEmail: jest.fn().mockResolvedValue(true),
}));

jest.mock("../utils/storage", () => ({
  uploadFile: jest.fn().mockResolvedValue("https://example.com/file.jpg"),
  deleteFile: jest.fn().mockResolvedValue(true),
}));

// Setup before all tests
beforeAll(async () => {
  // Close any existing connection
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }

  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();
  await mongoose.connect(mongoUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
});

// Clean up after each test
afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany();
  }

  // Clear all mocks
  jest.clearAllMocks();
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

// Helper functions for tests
const createTestUser = async (userData = {}) => {
  const defaultUserData = {
    email: `test${Date.now()}@example.com`,
    password: "password123",
    username: `testuser${Date.now()}`,
    firstName: "Test",
    lastName: "User",
    role: "user",
    ...userData,
  };

  const user = new User(defaultUserData);
  await user.save();
  return user;
};

const createTestOrganization = async (orgData = {}) => {
  const defaultOrgData = {
    name: `Test Org ${Date.now()}`,
    description: "A test organization",
    ...orgData,
  };

  const org = new Organization(defaultOrgData);
  await org.save();
  return org;
};

const getAuthToken = async (user) => {
  const response = await request(app).post("/api/auth/login").send({
    email: user.email,
    password: "password123",
  });

  return response.body.token;
};

module.exports = {
  app,
  server,
  request,
  createTestUser,
  createTestOrganization,
  getAuthToken,
};
