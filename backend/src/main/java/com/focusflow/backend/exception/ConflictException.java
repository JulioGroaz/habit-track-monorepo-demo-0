package com.focusflow.backend.exception;

/**
 * Responsibility: Signals a business conflict such as duplicate unique constraints. Architecture:
 * Service-layer exception mapped by the API exception handler. Why: Allows controllers to surface
 * 409 conflicts with structured error responses.
 */
public class ConflictException extends RuntimeException {
  public ConflictException(String message) {
    super(message);
  }
}
