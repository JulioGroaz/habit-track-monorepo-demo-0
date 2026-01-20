package com.template.backend;

import static org.assertj.core.api.Assertions.assertThat;

import com.template.backend.dto.NoteRequest;
import com.template.backend.entity.Note;
import com.template.backend.entity.User;
import com.template.backend.repository.UserRepository;
import com.template.backend.service.NoteService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class NoteServiceTest {

  @Autowired
  private NoteService noteService;

  @Autowired
  private UserRepository userRepository;

  @Test
  void createUpdateDeleteNote() {
    User user = new User("note@example.com", "hash");
    userRepository.save(user);

    Note note = noteService.createNote(user, new NoteRequest("Title", "Content"));
    assertThat(note.getId()).isNotNull();

    List<Note> notes = noteService.getNotes(user);
    assertThat(notes).hasSize(1);

    Note updated = noteService.updateNote(user, note.getId(), new NoteRequest("New", "Body"));
    assertThat(updated.getTitle()).isEqualTo("New");

    noteService.deleteNote(user, note.getId());
    assertThat(noteService.getNotes(user)).isEmpty();
  }
}
