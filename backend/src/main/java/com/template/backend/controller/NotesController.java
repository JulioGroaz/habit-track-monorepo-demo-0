package com.template.backend.controller;

import com.template.backend.dto.NoteRequest;
import com.template.backend.dto.NoteResponse;
import com.template.backend.entity.User;
import com.template.backend.service.NoteService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * CRUD endpoints for notes scoped to the authenticated user.
 */
@RestController
@RequestMapping("/api/notes")
public class NotesController {

  private final NoteService noteService;

  public NotesController(NoteService noteService) {
    this.noteService = noteService;
  }

  /**
   * Lists notes owned by the authenticated user.
   */
  @GetMapping
  public List<NoteResponse> list(@AuthenticationPrincipal User user) {
    return noteService.getNotes(user).stream().map(NoteResponse::from).toList();
  }

  /**
   * Creates a new note for the authenticated user.
   */
  @PostMapping
  public NoteResponse create(
      @AuthenticationPrincipal User user,
      @Valid @RequestBody NoteRequest request) {
    return NoteResponse.from(noteService.createNote(user, request));
  }

  /**
   * Updates a note owned by the authenticated user.
   */
  @PutMapping("/{id}")
  public NoteResponse update(
      @AuthenticationPrincipal User user,
      @PathVariable Long id,
      @Valid @RequestBody NoteRequest request) {
    return NoteResponse.from(noteService.updateNote(user, id, request));
  }

  /**
   * Deletes a note owned by the authenticated user.
   */
  @DeleteMapping("/{id}")
  public ResponseEntity<Void> delete(
      @AuthenticationPrincipal User user,
      @PathVariable Long id) {
    noteService.deleteNote(user, id);
    return ResponseEntity.noContent().build();
  }
}
