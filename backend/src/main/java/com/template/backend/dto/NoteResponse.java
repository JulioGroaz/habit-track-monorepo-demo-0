package com.template.backend.dto;

import com.template.backend.entity.Note;
import java.time.Instant;

/** Response model for notes exposed via the API. */
public record NoteResponse(
    Long id, String title, String content, Instant createdAt, Instant updatedAt) {

  /** Maps a domain entity to its API representation. */
  public static NoteResponse from(Note note) {
    return new NoteResponse(
        note.getId(), note.getTitle(), note.getContent(), note.getCreatedAt(), note.getUpdatedAt());
  }
}
