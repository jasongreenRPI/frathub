const mongoose = require("mongoose");
const User = require("./user");
const bcrypt = require("bcrypt");

const organizationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Organization name is required"],
      trim: true,
      unique: true,
    },
    description: {
      type: String,
      required: [true, "Organization description is required"],
      trim: true,
    },
    logo: {
      type: String,
      default: null,
    },
    members: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
        },
        role: {
          type: String,
          enum: ["member", "officer", "admin"],
          default: "member",
        },
        joinedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    events: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Event",
      },
    ],
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

class organizationInterface {
  static async createOrganization(name, superUserId, key) {
    if (!name || !superUserId) {
      throw new Error("Both name and superUserId are required");
    }

    // Check if organization with same name already exists
    const existingOrg = await this.findOne({ name });
    if (existingOrg) {
      throw new Error("Organization with this name already exists");
    }

    const hashKey = await bcrypt.hash(key, 10);
    const organization = new this({
      name,
      superUserId,
      current_encrypted_key: hashKey,
    });

    await organization.save();

    return { organization, hashKey };
  }

  static async addMember(orgId, memberId, roles = []) {
    if (!orgId || !memberId) {
      throw new Error("Both orgId and memberId are required");
    }

    const org = await this.findById(orgId);
    if (!org) {
      throw new Error("Organization not found");
    }

    const user = await User.findById(memberId);
    if (!user) {
      throw new Error("User not found");
    }

    // Check if the user is already a member
    if (org.hasMember(memberId)) {
      throw new Error("User is already a member of this organization");
    }

    // Add user to memberIds
    org.members.push({
      user: memberId,
      role: roles.includes("officer") ? "officer" : "member",
    });

    // Update the user's orgId
    user.orgId = orgId;

    org.updatedAt = new Date();

    await org.save();
    await user.save();

    return org;
  }

  hasMember(memberId) {
    return this.members.some(
      (member) => member.user.toString() === memberId.toString()
    );
  }

  hasOfficer(userId) {
    return this.members.some(
      (member) =>
        member.user.toString() === userId.toString() &&
        member.role === "officer"
    );
  }

  isSuperUser(userId) {
    return this.superUserId.toString() === userId.toString();
  }

  static async removeMember(orgId, memberId) {
    if (!orgId || !memberId) {
      throw new Error("Both orgId and memberId are required");
    }

    const org = await this.findById(orgId);
    if (!org) {
      throw new Error("Organization not found");
    }

    const user = await User.findById(memberId);
    if (!user) {
      throw new Error("User not found");
    }

    // Check if the user is a member
    if (!org.hasMember(memberId)) {
      throw new Error("User is not a member of this organization");
    }

    // Cannot remove super user
    if (org.isSuperUser(memberId)) {
      throw new Error("Cannot remove the organization's super user");
    }

    // Remove from members
    org.members = org.members.filter(
      (member) => member.user.toString() !== memberId.toString()
    );

    // Update user's orgId and role
    user.orgId = null;
    user.role = "guest";

    org.updatedAt = new Date();

    await org.save();
    await user.save();

    return org;
  }

  static async updateMemberRole(orgId, memberId, newRole) {
    if (!orgId || !memberId || !newRole) {
      throw new Error("orgId, memberId, and newRole are required");
    }

    if (!["member", "officer"].includes(newRole)) {
      throw new Error("newRole must be either 'member' or 'officer'");
    }

    const org = await this.findById(orgId);
    if (!org) {
      throw new Error("Organization not found");
    }

    const user = await User.findById(memberId);
    if (!user) {
      throw new Error("User not found");
    }

    // Check if the user is a member
    if (!org.hasMember(memberId)) {
      throw new Error("User is not a member of this organization");
    }

    // Cannot change super user's role
    if (org.isSuperUser(memberId)) {
      throw new Error("Cannot change the organization's super user role");
    }

    // Update member role
    org.members = org.members.map((member) =>
      member.user.toString() === memberId.toString()
        ? { ...member, role: newRole }
        : member
    );

    org.updatedAt = new Date();

    await org.save();
    await user.save();

    return org;
  }

  static async getOrganization(orgId) {
    if (!orgId) {
      throw new Error("orgId is required");
    }

    const org = await this.findById(orgId);
    if (!org) {
      throw new Error("Organization not found");
    }

    return org;
  }

  static async getOrganizationByName(name) {
    if (!name) {
      throw new Error("Name is required");
    }

    const org = await this.findOne({ name });

    if (!org) {
      throw new Error("Organization not found");
    }

    return org;
  }

  static async deleteOrganization(orgId, userId) {
    if (!orgId || !userId) {
      throw new Error("Both orgId and userId are required");
    }

    const user = await User.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }

    if (user.role !== "superuser") {
      throw new Error("Only superusers can delete organizations");
    }

    const org = await this.findById(orgId);
    if (!org) {
      throw new Error("Organization not found");
    }

    // Update all members to remove their association with this org
    await User.updateMany(
      { orgId: orgId },
      { $set: { orgId: null, role: "user" } }
    );

    const result = await this.deleteOne({ _id: orgId });
    if (result.deletedCount === 0) {
      throw new Error("Failed to delete organization");
    }

    return { success: true };
  }

  static async verifyOrganizationKey(orgId, key) {
    if (!orgId || !key) {
      throw new Error("Both orgId and key are required");
    }

    const organization = await this.findById(orgId);
    if (!organization) {
      throw new Error("Organization not found");
    }

    // Use bcrypt.compare for secure comparison instead of == operator
    return await bcrypt.compare(key, organization.current_encrypted_key);
  }

  static async regenerateAccessKey(orgId, userId, newKey) {
    if (!orgId || !userId) {
      throw new Error("Both orgId and userId are required");
    }

    const user = await User.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }

    const org = await this.findById(orgId);
    if (!org) {
      throw new Error("Organization not found");
    }

    // Verify user is the superuser of this organization
    if (!org.isSuperUser(userId) && user.role !== "superuser") {
      throw new Error(
        "Only the organization's super user or a superuser can regenerate access keys"
      );
    }

    // Hash the new key
    const hashedKey = await bcrypt.hash(newKey, 10);

    // Update the organization with the new key
    org.current_encrypted_key = hashedKey;
    org.updatedAt = new Date();
    await org.save();

    // Return the unhashed key so it can be shared with the user
    return { success: true, newKey };
  }

  static async updateSettings(orgId, userId, settingsUpdate) {
    if (!orgId || !userId) {
      throw new Error("Both orgId and userId are required");
    }

    const org = await this.findById(orgId);
    if (!org) {
      throw new Error("Organization not found");
    }

    const user = await User.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }

    // Verify user is authorized to update settings
    if (
      !org.isSuperUser(userId) &&
      !org.hasOfficer(userId) &&
      user.role !== "superuser"
    ) {
      throw new Error(
        "Only officers, the super user, or superusers can update organization settings"
      );
    }

    // Update settings
    if (settingsUpdate.hasOwnProperty("openQueue")) {
      org.settings.openQueue = settingsUpdate.openQueue;
    }

    if (settingsUpdate.hasOwnProperty("allowExternalUsers")) {
      org.settings.allowExternalUsers = settingsUpdate.allowExternalUsers;
    }

    org.updatedAt = new Date();
    await org.save();

    return org;
  }

  static async getAllMembers(orgId) {
    if (!orgId) {
      throw new Error("orgId is required");
    }

    const org = await this.findById(orgId).populate("members.user");
    if (!org) {
      throw new Error("Organization not found");
    }

    return org.members.map((member) => member.user);
  }

  static async getAllOfficers(orgId) {
    if (!orgId) {
      throw new Error("orgId is required");
    }

    const org = await this.findById(orgId).populate("members.user");
    if (!org) {
      throw new Error("Organization not found");
    }

    return org.members
      .filter((member) => member.role === "officer")
      .map((member) => member.user);
  }
}

organizationSchema.loadClass(organizationInterface);
const Organization = mongoose.model("Organization", organizationSchema);
module.exports = Organization;
