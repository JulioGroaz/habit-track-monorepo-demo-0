package com.template.backend.service;

import com.template.backend.dto.NoteRequest;
import com.template.backend.entity.Note;
import com.template.backend.entity.User;
import com.template.backend.exception.ResourceNotFoundException;
import com.template.backend.repository.NoteRepository;
import java.util.List;
import org.springframework.stereotype.Service;

/** Note operations scoped to the authenticated user. */
@Service
public class NoteService {

  private final NoteRepository noteRepository;

  public NoteService(NoteRepository noteRepository) {
    this.noteRepository = noteRepository;
  }

  public List<Note> getNotes(User user) {
    return noteRepository.findAllByOwner(user);
  }

  public Note createNote(User user, NoteRequest request) {
    Note note = new Note();
    note.setOwner(user);
    note.setTitle(request.title());
    note.setContent(request.content());
    return noteRepository.save(note);
  }

  public Note updateNote(User user, Long id, NoteRequest request) {
    // Ensure the note belongs to the current user.
    Note note =
        noteRepository
            .findByIdAndOwner(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
    note.setTitle(request.title());
    note.setContent(request.content());
    return noteRepository.save(note);
  }

  public void deleteNote(User user, Long id) {
    // Ensure the note belongs to the current user.
    Note note =
        noteRepository
            .findByIdAndOwner(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
    noteRepository.delete(note);
  }
}
