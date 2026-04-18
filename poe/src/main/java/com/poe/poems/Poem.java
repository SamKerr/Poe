package com.poe.poems;

import java.time.Instant;
import java.time.LocalDate;

public record Poem(long id, String content, Instant createdAt, LocalDate publishDay) {}
