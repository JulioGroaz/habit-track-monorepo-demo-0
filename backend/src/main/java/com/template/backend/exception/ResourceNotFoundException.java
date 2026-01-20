package com.template.backend.exception;

/** Signals that an entity was not found or is not accessible to the caller. */
public class ResourceNotFoundException extends RuntimeException {

  public ResourceNotFoundException(String message) {
    super(message);
  }
}
