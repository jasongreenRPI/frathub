// Create a new file called seedDB.js or testOrg.js
require("dotenv").config({
  path: require("path").resolve(__dirname, "../../.env"),
});
const connectDB = require("../connect");
const Organization = require("../Schemas/organization");


// Connect to the database
connectDB();

const createTestOrg = async () => {
  try {
    // Check if test-org already exists
    const existingOrg = await Organization.findOne({ name: "test-org" });

    if (existingOrg) {
      console.log("test-org already exists:", existingOrg);
      process.exit(0);
    }

    const testOrg = new Organization({
      name: "test-org",
      current_encrypted_key: "some-encrypted-key-value",
      settings: {
        openQueue: true,
        allowExternalUsers: false,
      },
    });

    const savedOrg = await testOrg.save();
    console.log("Organization saved successfully:", savedOrg);
    process.exit(0);
  } catch (error) {
    console.error("Error saving organization:", error);
    process.exit(1);
  }
};

createTestOrg();
