const { createTestUser, request, app } = require("./setup");

const timestamp = Date.now();

const userData = {
  email: `user@test.com`,
  password: "password123",
  username: "testuser",
  firstName: "Test",
  lastName: "User",
  role: "user",
};

const adminData = {
  email: `admin@test.com`,
  password: "password123",
  username: "adminuser",
  firstName: "Admin",
  lastName: "User",
  role: "admin",
};

const officerData = {
  email: `officer@test.com`,
  password: "password123",
  username: "officeruser",
  firstName: "Officer",
  lastName: "User",
  role: "officer",
};

describe("Auth Routes", () => {
  describe("POST /api/auth/resgister | POST /api/auth/login", () => {
    it("Should register a new user succesfully and log them in", async () => {
      const response = await request(app)
        .post("/api/auth/register")
        .send(userData);
      expect(response.status).toBe(201);

      const response2 = await request(app)
        .post("/api/auth/register")
        .send(adminData);
      expect(response2.status).toBe(201);

      const response3 = await request(app)
        .post("/api/auth/register")
        .send(officerData);
      expect(response3.status).toBe(201);

      const response4 = await request(app)
        .post("/api/auth/login")
        .send(userData);
      expect(response4.status).toBe(200);

      const response5 = await request(app)
        .post("/api/auth/login")
        .send(adminData);
      expect(response5.status).toBe(200);

      const response6 = await request(app)
        .post("/api/auth/login")
        .send(officerData);
      expect(response6.status).toBe(200);
    });
  });
});
