// Required packages
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

// User Schema
const userSchema = mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    validate: (value) => /^\S+@\S+\.\S+$/.test(value),
  },
  password: {
    type: String,
    required: true,
    // No select: false - password will be included in queries
  },
  username: {
    type: String,
    required: true,
    unique: true,
    match: [/^[a-z0-9_-]{3,16}$/, "Invalid username format"],
  },
  orgId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Organization",
  },
  firstName: String,
  lastName: String,
  role: {
    type: String,
    enum: ["user", "officer", "superuser", "guest", "admin"],
    default: "user",
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  lastLogin: {
    type: Date,
  },
  isActive: {
    type: Boolean,
    default: false,
  },
});

class UserInterface {
  getFullName() {
    return `${this.firstName}` + " " + `${this.lastName}`;
  }

  static async signUp(email, password, { ...fields }) {
    if (!email || !password) {
      throw new Error("Email and password are required");
    }

    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!emailRegex.test(email)) {
      throw new Error("Invalid email format");
    }

    const existingUser = await this.findOne({ email });
    if (existingUser) {
      throw new Error("Email already registered");
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = new this({
      email,
      password: hashedPassword,
      ...fields,
    });

    await user.save();
    return user;
  }

  static async login(email, password) {
    if (!email || !password) {
      throw new Error("Enter both username and password");
    }

    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!emailRegex.test(email)) {
      throw new Error("Invalid email format");
    }

    // No need to select password field since it's included by default now
    const user = await this.findOne({ email });
    if (!user) {
      throw new Error("User doesn't exist");
    }

    // Compare the provided password with the stored hash
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new Error("Invalid password");
    }

    // Update last login timestamp
    user.lastLogin = new Date();
    await user.save();

    return user;
  }
}

// Load the class methods into the schema
userSchema.loadClass(UserInterface);

// Create User model
const User = mongoose.model("User", userSchema);
module.exports = User;
