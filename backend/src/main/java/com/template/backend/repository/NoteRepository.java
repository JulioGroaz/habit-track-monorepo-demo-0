package com.template.backend.repository;

import com.template.backend.entity.Note;
import com.template.backend.entity.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Persistence gateway for {@link Note} entities scoped by owner. */
public interface NoteRepository extends JpaRepository<Note, Long> {

  List<Note> findAllByOwner(User owner);

  Optional<Note> findByIdAndOwner(Long id, User owner);
}
