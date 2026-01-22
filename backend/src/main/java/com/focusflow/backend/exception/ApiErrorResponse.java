package com.focusflow.backend.exception;

/**
 * Responsibility: Standardizes error payloads returned by the API. Architecture: Shared error DTO
 * used by exception handlers and security entry points. Why: Keeps error responses consistent for
 * clients across all endpoints.
 */
public record ApiErrorResponse(ApiErrorResponse.ErrorBody error) {

  public static ApiErrorResponse of(String code, String message, Object details) {
    return new ApiErrorResponse(new ErrorBody(code, message, details));
  }

  public record ErrorBody(String code, String message, Object details) {}
}
