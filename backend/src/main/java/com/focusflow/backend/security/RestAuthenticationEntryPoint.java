package com.focusflow.backend.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.focusflow.backend.exception.ApiErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

/**
 * Responsibility: Returns JSON error payloads when authentication fails. Architecture: Security
 * component wired into the filter chain exception handling. Why: Keeps auth errors consistent with
 * the API error contract.
 */
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

  private final ObjectMapper objectMapper;

  public RestAuthenticationEntryPoint(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  @Override
  public void commence(
      HttpServletRequest request,
      HttpServletResponse response,
      AuthenticationException authException)
      throws IOException {
    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    ApiErrorResponse body = ApiErrorResponse.of("UNAUTHORIZED", "Authentication is required", null);
    objectMapper.writeValue(response.getOutputStream(), body);
  }
}
