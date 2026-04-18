package com.poe.poems.model;

import java.time.Instant;
import java.time.LocalDate;

public record Poem(long id, String content, Instant createdAt, LocalDate publishDay) {}
