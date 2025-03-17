const express = require("express");
const Organization = require("../database/Schemas/organization");
const {
  authenticateToken,
  authorizeRole,
} = require("../middleware/auth.middleware");
const router = express.Router();

// Get all organizations (admin only)
router.get(
  "/",
  authenticateToken,
  authorizeRole(["admin"]),
  async (req, res) => {
    try {
      const organizations = await Organization.find();
      res.status(200).json({
        success: true,
        count: organizations.length,
        data: organizations,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// Create an organization (user who makes it is superuser)
router.post("/create-organization", authenticateToken, async (req, res) => {
  try {
    const { superUserId, orgName, key } = req.body;
    const { organization, hashKey } = await Organization.createOrganization(
      orgName,
      superUserId,
      key
    );

    if (!organization || !hashKey) {
      throw new Error("Organization creation failed");
    }

    res.status(200).json({
      success: true,
      data: { organization, hashKey },
    });
  } catch (error) {
    res.status(404).json({
      success: false,
      message: error.message,
    });
  }
});

// Get organization by ID
router.get("/:id", authenticateToken, async (req, res) => {
  try {
    const organization = await Organization.getOrganization(req.params.id);

    // Check if user belongs to org or is superuser
    if (
      req.user.role !== "superuser" &&
      organization.superUserId.toString() !== req.user.userId &&
      !organization.memberIds.includes(req.user.userId) &&
      !organization.officerIds.includes(req.user.userId)
    ) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You do not belong to this organization.",
      });
    }

    res.status(200).json({
      success: true,
      data: organization,
    });
  } catch (error) {
    res.status(404).json({
      success: false,
      message: error.message,
    });
  }
});

// Get organization by name
router.get("/name/:name", authenticateToken, async (req, res) => {
  try {
    const organization = await Organization.getOrganizationByName(
      req.params.name
    );

    // Check if user belongs to org or is superuser
    if (
      req.user.role !== "superuser" &&
      organization.superUserId.toString() !== req.user.userId &&
      !organization.memberIds.includes(req.user.userId) &&
      !organization.officerIds.includes(req.user.userId)
    ) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You do not belong to this organization.",
      });
    }

    res.status(200).json({
      success: true,
      data: organization,
    });
  } catch (error) {
    res.status(404).json({
      success: false,
      message: error.message,
    });
  }
});

// Create a new organization
router.post("/", authenticateToken, async (req, res) => {
  try {
    const { name } = req.body;
    const { organization, hashKey } = await Organization.createOrganization(
      name,
      req.user.userId
    );

    res.status(201).json({
      success: true,
      data: organization,
      accessKey: hashKey, // Return the unhashed key for initial setup
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Delete an organization
router.delete(
  "/:id",
  authenticateToken,
  authorizeRole(["superuser"]),
  async (req, res) => {
    try {
      const result = await Organization.deleteOrganization(
        req.params.id,
        req.user.userId
      );
      res.status(200).json({
        success: true,
        message: "Organization deleted successfully",
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// Regenerate access key
router.post(
  "/:id/regenerate-key",
  authenticateToken,
  authorizeRole(["superuser"]),
  async (req, res) => {
    try {
      const { newKey } = await Organization.regenerateAccessKey(
        req.params.id,
        req.user.userId,
        req.body.key
      );
      res.status(200).json({
        success: true,
        newKey, // Return the unhashed key
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// Verify organization key
router.post("/verify-key", authenticateToken, async (req, res) => {
  try {
    const { orgId, key } = req.body;
    const isValid = await Organization.verifyOrganizationKey(orgId, key);

    res.status(200).json({
      success: true,
      isValid,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
