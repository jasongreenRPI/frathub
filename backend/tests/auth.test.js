const { createTestUser, request, app } = require("./setup");

describe("Auth Routes", () => {
  describe("POST /api/auth/register", () => {
    it("should register a new user successfully", async () => {
      const userData = {
        email: "newuser@example.com",
        password: "password123",
        username: "newuser",
        firstName: "New",
        lastName: "User",
      };

      const response = await request(app)
        .post("/api/auth/register")
        .send(userData);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.token).toBeDefined();
      expect(response.body.user).toBeDefined();
      expect(response.body.user.email).toBe(userData.email);
      expect(response.body.user.username).toBe(userData.username);
    });

    it("should not register a user with existing email", async () => {
      const user = await createTestUser();

      const response = await request(app).post("/api/auth/register").send({
        email: user.email,
        password: "password123",
        username: "differentuser",
        firstName: "Different",
        lastName: "User",
      });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain("already registered");
    });

    it("should not register a user with invalid email format", async () => {
      const response = await request(app).post("/api/auth/register").send({
        email: "invalid-email",
        password: "password123",
        username: "invaliduser",
        firstName: "Invalid",
        lastName: "User",
      });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain("Invalid email format");
    });
  });

  describe("POST /api/auth/login", () => {
    it("should login user successfully", async () => {
      const user = await createTestUser();

      const response = await request(app).post("/api/auth/login").send({
        email: user.email,
        password: "password123",
      });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.token).toBeDefined();
      expect(response.body.user).toBeDefined();
      expect(response.body.user.email).toBe(user.email);
    });

    it("should not login with incorrect password", async () => {
      const user = await createTestUser();

      const response = await request(app).post("/api/auth/login").send({
        email: user.email,
        password: "wrongpassword",
      });

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe("Invalid password");
    });

    it("should not login with non-existent email", async () => {
      const response = await request(app).post("/api/auth/login").send({
        email: "nonexistent@example.com",
        password: "password123",
      });

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe("User doesn't exist");
    });
  });
});
