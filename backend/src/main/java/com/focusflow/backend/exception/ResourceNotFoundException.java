package com.focusflow.backend.exception;

/**
 * Responsibility: Signals that a requested resource does not exist or is not accessible.
 * Architecture: Service-layer exception mapped by the API exception handler. Why: Provides a clear,
 * domain-specific failure mode for 404 responses.
 */
public class ResourceNotFoundException extends RuntimeException {
  public ResourceNotFoundException(String message) {
    super(message);
  }
}
