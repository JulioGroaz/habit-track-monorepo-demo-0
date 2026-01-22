package com.focusflow.backend.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import org.springframework.context.annotation.Configuration;

/**
 * Responsibility: Defines OpenAPI metadata for Swagger documentation. Architecture: Configuration
 * layer for API documentation tooling. Why: Keeps API branding and descriptions centralized.
 */
@Configuration
@OpenAPIDefinition(
    info =
        @Info(
            title = "FocusFlow API",
            version = "v1",
            description = "Backend API for FocusFlow goals, routines, check-ins, and sync."))
public class OpenApiConfig {}
