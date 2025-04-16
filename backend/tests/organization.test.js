const {
  createTestUser,
  createTestOrganization,
  getAuthToken,
  request,
  app,
} = require("./setup");
const Organization = require("../database/Schemas/organization");

describe("Organization Routes", () => {
  let adminUser;
  let regularUser;
  let adminToken;
  let userToken;
  let testOrg;
  let orgId;

  beforeEach(async () => {
    // Create test users
    adminUser = await createTestUser({ role: "admin" });
    regularUser = await createTestUser({ role: "user" });

    // Get auth tokens
    adminToken = await getAuthToken(adminUser);
    userToken = await getAuthToken(regularUser);

    // Create a test organization
    testOrg = await createTestOrganization();
    orgId = testOrg._id.toString();
  });

  describe("GET /api/organizations", () => {
    it("Should get all organizations (authenticated)", async () => {
      const response = await request(app)
        .get("/api/organizations")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it("Should fail without authentication", async () => {
      const response = await request(app).get("/api/organizations");

      expect(response.status).toBe(401);
    });
  });

  describe("GET /api/organizations/:id", () => {
    it("Should get organization by ID (authenticated)", async () => {
      const response = await request(app)
        .get(`/api/organizations/${orgId}`)
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data._id).toBe(orgId);
    });

    it("Should fail with invalid organization ID", async () => {
      const response = await request(app)
        .get("/api/organizations/invalidid")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe("POST /api/organizations", () => {
    it("Should create a new organization (admin only)", async () => {
      const newOrgData = {
        name: "New Test Organization",
        description: "A new test organization",
      };

      const response = await request(app)
        .post("/api/organizations")
        .set("Authorization", `Bearer ${adminToken}`)
        .send(newOrgData);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(newOrgData.name);
      expect(response.body.data.description).toBe(newOrgData.description);
    });

    it("Should fail when regular user tries to create organization", async () => {
      const newOrgData = {
        name: "New Test Organization",
        description: "A new test organization",
      };

      const response = await request(app)
        .post("/api/organizations")
        .set("Authorization", `Bearer ${userToken}`)
        .send(newOrgData);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("PUT /api/organizations/:id", () => {
    it("Should update an organization (admin only)", async () => {
      const updateData = {
        name: "Updated Organization",
        description: "An updated test organization",
      };

      const response = await request(app)
        .put(`/api/organizations/${orgId}`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send(updateData);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(updateData.name);
      expect(response.body.data.description).toBe(updateData.description);
    });

    it("Should fail when regular user tries to update organization", async () => {
      const updateData = {
        name: "Updated Organization",
        description: "An updated test organization",
      };

      const response = await request(app)
        .put(`/api/organizations/${orgId}`)
        .set("Authorization", `Bearer ${userToken}`)
        .send(updateData);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("DELETE /api/organizations/:id", () => {
    it("Should delete an organization (admin only)", async () => {
      const response = await request(app)
        .delete(`/api/organizations/${orgId}`)
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify organization was deleted
      const deletedOrg = await Organization.findById(orgId);
      expect(deletedOrg).toBeNull();
    });

    it("Should fail when regular user tries to delete organization", async () => {
      const response = await request(app)
        .delete(`/api/organizations/${orgId}`)
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);

      // Verify organization still exists
      const org = await Organization.findById(orgId);
      expect(org).not.toBeNull();
    });
  });
});
