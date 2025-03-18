const {
  createTestUser,
  createTestOrganization,
  getAuthToken,
  request,
  app,
} = require("./setup");

describe("Organization Routes", () => {
  let adminUser;
  let regularUser;
  let adminToken;
  let userToken;
  let testOrg;

  beforeEach(async () => {
    // Create admin user
    adminUser = await createTestUser({ role: "superuser" });
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

  describe("GET /api/organizations", () => {
    it("should get all organizations (admin only)", async () => {
      const response = await request(app)
        .get("/api/organizations")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it("should not allow non-admin users to get all organizations", async () => {
      const response = await request(app)
        .get("/api/organizations")
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("POST /api/organizations/create-organization", () => {
    it("should create a new organization", async () => {
      const response = await request(app)
        .post("/api/organizations/create-organization")
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          orgName: "New Organization",
          key: "neworgkey123",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.organization).toBeDefined();
      expect(response.body.data.hashKey).toBeDefined();
    });

    it("should not create organization with existing name", async () => {
      const response = await request(app)
        .post("/api/organizations/create-organization")
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          orgName: testOrg.name,
          key: "neworgkey123",
        });

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });

  describe("GET /api/organizations/:id", () => {
    it("should get organization by ID for authorized user", async () => {
      const response = await request(app)
        .get(`/api/organizations/${testOrg._id}`)
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data._id.toString()).toBe(testOrg._id.toString());
    });

    it("should not get organization for unauthorized user", async () => {
      const unauthorizedUser = await createTestUser({
        email: "unauthorized@example.com",
        username: "unauthorized",
      });
      const unauthorizedToken = await getAuthToken(unauthorizedUser);

      const response = await request(app)
        .get(`/api/organizations/${testOrg._id}`)
        .set("Authorization", `Bearer ${unauthorizedToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("GET /api/organizations/name/:name", () => {
    it("should get organization by name for authorized user", async () => {
      const response = await request(app)
        .get(`/api/organizations/name/${testOrg.name}`)
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(testOrg.name);
    });

    it("should not get organization by name for unauthorized user", async () => {
      const unauthorizedUser = await createTestUser({
        email: "unauthorized@example.com",
        username: "unauthorized",
      });
      const unauthorizedToken = await getAuthToken(unauthorizedUser);

      const response = await request(app)
        .get(`/api/organizations/name/${testOrg.name}`)
        .set("Authorization", `Bearer ${unauthorizedToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("DELETE /api/organizations/:id", () => {
    it("should delete organization (admin only)", async () => {
      const response = await request(app)
        .delete(`/api/organizations/${testOrg._id}`)
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify organization is deleted
      const deletedOrg = await Organization.findById(testOrg._id);
      expect(deletedOrg).toBeNull();
    });

    it("should not allow non-admin users to delete organization", async () => {
      const response = await request(app)
        .delete(`/api/organizations/${testOrg._id}`)
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("POST /api/organizations/:id/regenerate-key", () => {
    it("should regenerate organization key (superuser only)", async () => {
      const response = await request(app)
        .post(`/api/organizations/${testOrg._id}/regenerate-key`)
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          key: "newkey123",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.newKey).toBeDefined();
    });

    it("should not allow non-superuser to regenerate key", async () => {
      const regularUser2 = await createTestUser({
        email: "regular2@example.com",
        username: "regularuser2",
      });
      const regularToken2 = await getAuthToken(regularUser2);

      const response = await request(app)
        .post(`/api/organizations/${testOrg._id}/regenerate-key`)
        .set("Authorization", `Bearer ${regularToken2}`)
        .send({
          key: "newkey123",
        });

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("POST /api/organizations/verify-key", () => {
    it("should verify valid organization key", async () => {
      const response = await request(app)
        .post("/api/organizations/verify-key")
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          orgId: testOrg._id,
          key: "testkey123",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.isValid).toBe(true);
    });

    it("should reject invalid organization key", async () => {
      const response = await request(app)
        .post("/api/organizations/verify-key")
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          orgId: testOrg._id,
          key: "wrongkey",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.isValid).toBe(false);
    });
  });
});
