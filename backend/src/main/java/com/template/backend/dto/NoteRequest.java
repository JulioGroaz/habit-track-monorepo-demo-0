package com.template.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Payload for creating or updating notes. */
public record NoteRequest(
    @NotBlank @Size(max = 120) String title, @NotBlank @Size(max = 2000) String content) {}
