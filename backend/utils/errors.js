/**
 * Custom error classes for the application
 *
 * These error classes extend the built-in Error class and add additional properties
 * to help with error handling and response formatting.
 */

class AppError extends Error {
  constructor(message, statusCode = 500, errors = []) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors;
    this.status = `${statusCode}`.startsWith("4") ? "fail" : "error";
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

class BadRequestError extends AppError {
  constructor(message = "Bad Request", errors = []) {
    super(message, 400, errors);
  }
}

class UnauthorizedError extends AppError {
  constructor(message = "Unauthorized", errors = []) {
    super(message, 401, errors);
  }
}

class ForbiddenError extends AppError {
  constructor(message = "Forbidden", errors = []) {
    super(message, 403, errors);
  }
}

class NotFoundError extends AppError {
  constructor(message = "Not Found", errors = []) {
    super(message, 404, errors);
  }
}

class ConflictError extends AppError {
  constructor(message = "Conflict", errors = []) {
    super(message, 409, errors);
  }
}

class ValidationError extends AppError {
  constructor(message = "Validation Error", errors = []) {
    super(message, 422, errors);
  }
}

/**
 * Error handler middleware
 *
 * This middleware catches errors and formats them for the client.
 */
const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || "error";

  // Development error response
  if (process.env.NODE_ENV === "development") {
    res.status(err.statusCode).json({
      success: false,
      status: err.status,
      error: err,
      message: err.message,
      stack: err.stack,
    });
  }
  // Production error response
  else {
    // Operational, trusted error: send message to client
    if (err.isOperational) {
      res.status(err.statusCode).json({
        success: false,
        status: err.status,
        message: err.message,
        errors: err.errors,
      });
    }
    // Programming or other unknown error: don't leak error details
    else {
      // Log error
      console.error("ERROR 💥", err);

      // Send generic message
      res.status(500).json({
        success: false,
        status: "error",
        message: "Something went wrong",
      });
    }
  }
};

module.exports = {
  AppError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  ValidationError,
  errorHandler,
};
