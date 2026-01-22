package com.focusflow.backend.integration;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Responsibility: Provides a shared PostgreSQL Testcontainer for integration tests. Architecture:
 * Test infrastructure base class supplying dynamic datasource settings. Why: Ensures integration
 * tests run against the same database engine as production.
 */
@Testcontainers
public abstract class IntegrationTestBase {

  @Container
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16").withDatabaseName("focusflow_test");

  @DynamicPropertySource
  static void registerDatabaseProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", POSTGRES::getUsername);
    registry.add("spring.datasource.password", POSTGRES::getPassword);
  }
}
