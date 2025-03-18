const {
  createTestUser,
  createTestOrganization,
  getAuthToken,
  request,
  app,
} = require("./setup");
const Queue = require("../database/Schemas/queue");
const Organization = require("../database/Schemas/organization");

describe("Queue Routes", () => {
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

  describe("GET /api/queues/org/:orgId", () => {
    it("should get queue status for organization member", async () => {
      const response = await request(app)
        .get(`/api/queues/org/${testOrg._id}`)
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.orgId.toString()).toBe(testOrg._id.toString());
    });

    it("should create new queue if it does not exist", async () => {
      const response = await request(app)
        .get(`/api/queues/org/${testOrg._id}`)
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();

      // Verify queue was created in database
      const queue = await Queue.findOne({ orgId: testOrg._id });
      expect(queue).toBeDefined();
    });

    it("should not get queue status for non-member", async () => {
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
        .get(`/api/queues/org/${testOrg._id}`)
        .set("Authorization", `Bearer ${otherToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("PATCH /api/queues/org/:orgId", () => {
    it("should update queue status for officer", async () => {
      // Make regular user an officer
      await Organization.updateMemberRole(
        testOrg._id,
        regularUser._id,
        "officer"
      );

      const response = await request(app)
        .patch(`/api/queues/org/${testOrg._id}`)
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          status: "open",
          openToOutside: true,
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe("open");
      expect(response.body.data.openToOutside).toBe(true);
    });

    it("should update queue status for admin", async () => {
      const response = await request(app)
        .patch(`/api/queues/org/${testOrg._id}`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          status: "closed",
          openToOutside: false,
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe("closed");
      expect(response.body.data.openToOutside).toBe(false);
    });

    it("should not update queue status for regular member", async () => {
      const response = await request(app)
        .patch(`/api/queues/org/${testOrg._id}`)
        .set("Authorization", `Bearer ${userToken}`)
        .send({
          status: "open",
          openToOutside: true,
        });

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe("GET /api/queues", () => {
    it("should get all queues for admin", async () => {
      const response = await request(app)
        .get("/api/queues")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it("should not allow non-admin users to get all queues", async () => {
      const response = await request(app)
        .get("/api/queues")
        .set("Authorization", `Bearer ${userToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });
});
