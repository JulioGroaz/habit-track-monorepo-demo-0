package com.focusflow.backend.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.focusflow.backend.exception.ApiErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

/**
 * Responsibility: Returns JSON error payloads when access is denied. Architecture: Security
 * component wired into the filter chain exception handling. Why: Keeps authorization errors
 * consistent with the API error contract.
 */
@Component
public class RestAccessDeniedHandler implements AccessDeniedHandler {

  private final ObjectMapper objectMapper;

  public RestAccessDeniedHandler(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  @Override
  public void handle(
      HttpServletRequest request,
      HttpServletResponse response,
      AccessDeniedException accessDeniedException)
      throws IOException {
    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    ApiErrorResponse body = ApiErrorResponse.of("FORBIDDEN", "Access denied", null);
    objectMapper.writeValue(response.getOutputStream(), body);
  }
}
