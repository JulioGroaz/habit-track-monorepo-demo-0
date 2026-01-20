package com.template.backend.exception;

import java.util.HashMap;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

/**
 * Centralized error mapping to ProblemDetail responses.
 */
@RestControllerAdvice
public class ApiExceptionHandler {

  /**
   * Translates bean validation errors into a structured map.
   */
  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
    ProblemDetail problemDetail = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
    problemDetail.setTitle("Validation failed");

    Map<String, String> errors = new HashMap<>();
    for (FieldError error : ex.getBindingResult().getFieldErrors()) {
      errors.put(error.getField(), error.getDefaultMessage());
    }
    problemDetail.setProperty("errors", errors);

    return problemDetail;
  }

  /**
   * Not found errors for missing resources.
   */
  @ExceptionHandler(ResourceNotFoundException.class)
  public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
    ProblemDetail problemDetail = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
    problemDetail.setTitle("Resource not found");
    problemDetail.setDetail(ex.getMessage());
    return problemDetail;
  }

  /**
   * Converts ResponseStatusException into ProblemDetail while keeping the status.
   */
  @ExceptionHandler(ResponseStatusException.class)
  public ProblemDetail handleResponseStatus(ResponseStatusException ex) {
    ProblemDetail problemDetail = ProblemDetail.forStatus(ex.getStatusCode());
    if (ex.getReason() != null) {
      problemDetail.setDetail(ex.getReason());
    } else {
      problemDetail.setDetail("Request failed");
    }
    return problemDetail;
  }

  /**
   * Fallback for unexpected failures.
   */
  @ExceptionHandler(Exception.class)
  public ProblemDetail handleGeneric(Exception ex) {
    ProblemDetail problemDetail = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
    problemDetail.setTitle("Internal server error");
    return problemDetail;
  }
}
