package com.template.backend;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Spring Boot entry point for the template. Loads .env values into system properties before
 * bootstrapping.
 */
@SpringBootApplication
public class TemplateBackendApplication {

  public static void main(String[] args) {
    loadDotenv();
    SpringApplication.run(TemplateBackendApplication.class, args);
  }

  private static void loadDotenv() {
    // Load .env if present and do not override explicit env/system properties.
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
