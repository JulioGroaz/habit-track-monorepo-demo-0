package com.focusflow.backend;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Responsibility: Bootstraps the FocusFlow Spring Boot application. Architecture: Root entry point
 * that defines the base package for component scanning. Why: Centralizes startup concerns (like
 * loading .env) without leaking into business logic.
 */
@SpringBootApplication
public class FocusFlowApplication {

  public static void main(String[] args) {
    loadDotenv();
    SpringApplication.run(FocusFlowApplication.class, args);
  }

  private static void loadDotenv() {
    // Load .env if present while respecting real environment variables for production parity.
    Dotenv dotenv = Dotenv.configure().filename(".env").ignoreIfMissing().load();
    dotenv
        .entries()
        .forEach(
            entry -> {
              if (System.getProperty(entry.getKey()) == null
                  && System.getenv(entry.getKey()) == null) {
                System.setProperty(entry.getKey(), entry.getValue());
              }
            });
  }
}
