const {
  createTestUser,
  createTestOrganization,
  getAuthToken,
  request,
  app,
} = require("./setup");

describe("User Routes", () => {
  let adminUser;
  let regularUser;
  let adminToken;
  let userToken;
  let testOrg;

  beforeEach(async () => {
    // Create admin user
    adminUser = await createTestUser({ role: "superuser" }, "admin");
    adminToken = await getAuthToken(adminUser);

    // Create regular user
    regularUser = await createTestUser({
      email: "regular@example.com",
      username: "regularuser",
    });
    userToken = await getAuthToken(regularUser);

    // Create test organization
    const { organization } = await createTestOrganization({
      superUserId: regularUser._id,
    });
    testOrg = organization;
  });

  describe("GET /api/users/profile", () => {
    it("should get user profile", async () => {
      const response = await request(app)
        .get("/api/users/profile")
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data._id.toString()).toBe(
        regularUser._id.toString()
      );
      expect(response.body.data.password).toBeUndefined();
    });

    it("should not get profile without authentication", async () => {
      const response = await request(app).get("/api/users/profile");

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });
  });

  describe("GET /api/users", () => {
    it("should get all users (admin only)", async () => {
      const response = await request(app)
        .get("/api/users")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it("should not allow non-admin users to get all users", async () => {
      const response = await request(app)
        .get("/api/users")
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("GET /api/users/:id", () => {
    it("should get user by ID for admin", async () => {
      const response = await request(app)
        .get(`/api/users/${regularUser._id}`)
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data._id.toString()).toBe(
        regularUser._id.toString()
      );
    });

    it("should get user by ID for same organization member", async () => {
      const orgMember = await createTestUser({
        email: "member@example.com",
        username: "orgmember",
        orgId: testOrg._id,
      });
      const memberToken = await getAuthToken(orgMember);

      const response = await request(app)
        .get(`/api/users/${regularUser._id}`)
        .set("Authorization", `Bearer ${memberToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it("should not get user by ID for different organization member", async () => {
      const otherOrg = await createTestOrganization({
        name: "Other Organization",
        superUserId: adminUser._id,
      });
      const otherOrgMember = await createTestUser({
        email: "other@example.com",
        username: "othermember",
        orgId: otherOrg.organization._id,
      });
      const otherToken = await getAuthToken(otherOrgMember);

      const response = await request(app)
        .get(`/api/users/${regularUser._id}`)
        .set("Authorization", `Bearer ${otherToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("PUT /api/users/profile", () => {
    it("should update user profile", async () => {
      const updates = {
        firstName: "Updated",
        lastName: "Name",
        username: "updateduser",
      };

      const response = await request(app)
        .put("/api/users/profile")
        .set("Authorization", `Bearer ${userToken}`)
        .send(updates);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.firstName).toBe(updates.firstName);
      expect(response.body.data.lastName).toBe(updates.lastName);
      expect(response.body.data.username).toBe(updates.username);
    });

    it("should not update restricted fields", async () => {
      const updates = {
        email: "newemail@example.com",
        role: "admin",
        password: "newpassword",
      };

      const response = await request(app)
        .put("/api/users/profile")
        .set("Authorization", `Bearer ${userToken}`)
        .send(updates);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe("PATCH /api/users/:id/role", () => {
    it("should update user role (admin only)", async () => {
      const response = await request(app)
        .patch(`/api/users/${regularUser._id}/role`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          role: "officer",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.role).toBe("officer");
    });

    it("should not allow non-admin users to update roles", async () => {
      const response = await request(app)
        .patch(`/api/users/${regularUser._id}/role`)
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          role: "officer",
        });

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });

    it("should not update to invalid role", async () => {
      const response = await request(app)
        .patch(`/api/users/${regularUser._id}/role`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          role: "invalidrole",
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe("DELETE /api/users/:id", () => {
    it("should delete user (admin only)", async () => {
      const response = await request(app)
        .delete(`/api/users/${regularUser._id}`)
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify user is deleted
      const deletedUser = await User.findById(regularUser._id);
      expect(deletedUser).toBeNull();
    });

    it("should not allow non-admin users to delete users", async () => {
      const response = await request(app)
        .delete(`/api/users/${regularUser._id}`)
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });
});
