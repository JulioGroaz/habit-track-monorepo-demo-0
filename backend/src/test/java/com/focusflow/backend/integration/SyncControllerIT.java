package com.focusflow.backend.integration;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.focusflow.backend.dto.GoalSyncRequest;
import com.focusflow.backend.dto.RegisterRequest;
import com.focusflow.backend.dto.SyncPushRequest;
import com.focusflow.backend.entity.GoalStatus;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Responsibility: Integration tests for sync endpoints and conflict handling. Architecture:
 * API-layer test exercising sync workflows across service and repository layers. Why: Verifies that
 * older client updates are rejected with conflict payloads.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SyncControllerIT extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private ObjectMapper objectMapper;

  @Test
  void pushRejectsOlderClientUpdatesWithConflicts() throws Exception {
    String token = registerAndGetToken();

    UUID goalId = UUID.randomUUID();
    Instant freshClientTime = Instant.now().minusSeconds(60);
    Instant staleClientTime = Instant.now().minusSeconds(120);

    SyncPushRequest initialPush =
        new SyncPushRequest(
            List.of(
                new GoalSyncRequest(
                    goalId, "Focus", null, null, GoalStatus.ACTIVE, null, freshClientTime, null)),
            List.of(),
            List.of(),
            List.of());

    mockMvc
        .perform(
            post("/api/v1/sync/push")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(initialPush)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goals[0].id").value(goalId.toString()))
        .andExpect(jsonPath("$.conflicts").isEmpty());

    SyncPushRequest stalePush =
        new SyncPushRequest(
            List.of(
                new GoalSyncRequest(
                    goalId,
                    "Focus (old)",
                    null,
                    null,
                    GoalStatus.ACTIVE,
                    null,
                    staleClientTime,
                    null)),
            List.of(),
            List.of(),
            List.of());

    mockMvc
        .perform(
            post("/api/v1/sync/push")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(stalePush)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.conflicts[0].entityType").value("GOAL"))
        .andExpect(jsonPath("$.conflicts[0].reason").value("SERVER_NEWER"))
        .andExpect(jsonPath("$.conflicts[0].server.id").value(goalId.toString()))
        .andExpect(jsonPath("$.conflicts[0].client.id").value(goalId.toString()));
  }

  private String registerAndGetToken() throws Exception {
    RegisterRequest register = new RegisterRequest("sync@example.com", "Password1!");
    MvcResult result =
        mockMvc
            .perform(
                post("/api/v1/auth/register")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(register)))
            .andExpect(status().isOk())
            .andReturn();

    JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
    return json.get("token").asText();
  }
}
