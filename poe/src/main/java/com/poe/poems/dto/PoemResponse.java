package com.poe.poems.dto;

import com.poe.poems.model.Poem;
import java.time.Instant;
import java.time.LocalDate;

public record PoemResponse(long id, String content, Instant createdAt, LocalDate publishDay) {

  public static PoemResponse from(Poem poem) {
    return new PoemResponse(poem.id(), poem.content(), poem.createdAt(), poem.publishDay());
  }
}
