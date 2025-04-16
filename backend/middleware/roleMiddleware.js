/**
 * Role-based access control middleware
 *
 * This middleware checks if the user has the required role to access a resource.
 * It should be used after the authentication middleware.
 */

const { UnauthorizedError, ForbiddenError } = require("../utils/errors");

/**
 * Middleware to check if the user has the required role
 * @param {string[]} roles - Array of roles that are allowed to access the resource
 * @returns {Function} - Express middleware function
 */
const checkRole = (roles) => {
  return (req, res, next) => {
    // Check if user is authenticated
    if (!req.user) {
      return next(new UnauthorizedError("Authentication required"));
    }

    // Check if user has the required role
    if (!roles.includes(req.user.role)) {
      return next(new ForbiddenError("Insufficient permissions"));
    }

    // User has the required role, proceed to the next middleware
    next();
  };
};

/**
 * Middleware to check if the user is the owner of the resource
 * @param {Function} getResourceOwnerId - Function to get the owner ID from the request
 * @returns {Function} - Express middleware function
 */
const checkOwnership = (getResourceOwnerId) => {
  return (req, res, next) => {
    // Check if user is authenticated
    if (!req.user) {
      return next(new UnauthorizedError("Authentication required"));
    }

    // Get the resource owner ID
    const resourceOwnerId = getResourceOwnerId(req);

    // Check if user is the owner or an admin
    if (
      req.user.role !== "admin" &&
      req.user._id.toString() !== resourceOwnerId
    ) {
      return next(new ForbiddenError("Insufficient permissions"));
    }

    // User is the owner or an admin, proceed to the next middleware
    next();
  };
};

module.exports = {
  checkRole,
  checkOwnership,
};
