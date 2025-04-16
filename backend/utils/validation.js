/**
 * Validation utilities
 *
 * This module provides validation functions using the Joi library.
 * It helps ensure data integrity by validating input data against schemas.
 */

const Joi = require("joi");
const { ValidationError } = require("./errors");

/**
 * Validates data against a schema
 * @param {Object} data - The data to validate
 * @param {Object} schema - The Joi schema to validate against
 * @returns {Object} - The validated data
 * @throws {ValidationError} - If validation fails
 */
const validate = (data, schema) => {
  const { error, value } = schema.validate(data, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    const errors = error.details.map((detail) => ({
      field: detail.path.join("."),
      message: detail.message,
    }));
    throw new ValidationError("Validation failed", errors);
  }

  return value;
};

/**
 * Validation schemas
 */
const schemas = {
  // User schemas
  user: {
    create: Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().min(8).required(),
      username: Joi.string().min(3).max(30).required(),
      firstName: Joi.string().required(),
      lastName: Joi.string().required(),
      role: Joi.string().valid("user", "admin", "officer").default("user"),
    }),
    update: Joi.object({
      email: Joi.string().email(),
      password: Joi.string().min(8),
      username: Joi.string().min(3).max(30),
      firstName: Joi.string(),
      lastName: Joi.string(),
      role: Joi.string().valid("user", "admin", "officer"),
    }),
  },

  // Organization schemas
  organization: {
    create: Joi.object({
      name: Joi.string().required(),
      description: Joi.string().required(),
    }),
    update: Joi.object({
      name: Joi.string(),
      description: Joi.string(),
    }),
  },

  // Authentication schemas
  auth: {
    login: Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().required(),
    }),
    register: Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().min(8).required(),
      username: Joi.string().min(3).max(30).required(),
      firstName: Joi.string().required(),
      lastName: Joi.string().required(),
      role: Joi.string().valid("user", "admin", "officer").default("user"),
    }),
  },
};

module.exports = {
  validate,
  schemas,
};
