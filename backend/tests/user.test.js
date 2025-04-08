const { request, app } = require("./setup");

describe("User Routes", () => {
  let token;
  let userId;

  beforeAll(async () => {
    // Register a test user
    const registerResponse = await request(app)
      .post("/api/auth/register")
      .send({
        email: "test@test.com",
        password: "password123",
        username: "testuser",
        firstName: "Test",
        lastName: "User",
        role: "admin",
      });

    // Login to get token
    const loginResponse = await request(app).post("/api/auth/login").send({
      email: "test@test.com",
      password: "password123",
    });

    token = loginResponse.body.token;
    userId = registerResponse.body.user.id; // Changed back to id
  });

  it("Should get all users (authenticated)", async () => {
    const response = await request(app)
      .get("/api/users")
      .set("Authorization", `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
  });

  it("Should get user by ID (authenticated)", async () => {
    // First get all users to get a valid ID
    const allUsersResponse = await request(app)
      .get("/api/users")
      .set("Authorization", `Bearer ${token}`);

    const testUserId = allUsersResponse.body.data[0].id;

    const response = await request(app)
      .get(`/api/users/${testUserId}`)
      .set("Authorization", `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.id).toBe(testUserId);
  });

  it("Should fail without authentication", async () => {
    const response = await request(app).get("/api/users");

    expect(response.status).toBe(401);
  });
});
