package com.poe.poems.repository;

import com.poe.poems.model.Poem;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

@Repository
public class PoemRepository {

  private final JdbcTemplate jdbcTemplate;

  public PoemRepository(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  public long insertPoem(String content, String normalizedHash, Instant createdAt, LocalDate publishDay) {
    KeyHolder keyHolder = new GeneratedKeyHolder();

    jdbcTemplate.update(
        connection -> {
          PreparedStatement statement =
              connection.prepareStatement(
                  "INSERT INTO poems (content, normalized_hash, created_at, publish_day) VALUES (?, ?, ?, ?)",
                  Statement.RETURN_GENERATED_KEYS);
          statement.setString(1, content);
          statement.setString(2, normalizedHash);
          statement.setString(3, createdAt.toString());
          statement.setString(4, publishDay.toString());
          return statement;
        },
        keyHolder);

    Number key = keyHolder.getKey();
    if (key == null) {
      throw new IllegalStateException("Failed to create poem id");
    }
    return key.longValue();
  }

  public Optional<Poem> findById(long id) {
    return jdbcTemplate
        .query(
            "SELECT id, content, created_at, publish_day FROM poems WHERE id = ?",
            (rs, rowNum) ->
                new Poem(
                    rs.getLong("id"),
                    rs.getString("content"),
                    Instant.parse(rs.getString("created_at")),
                    LocalDate.parse(rs.getString("publish_day"))),
            id)
        .stream()
        .findFirst();
  }

  public List<Poem> findFeedByPublishDay(LocalDate publishDay, int limit) {
    return jdbcTemplate.query(
        """
            SELECT id, content, created_at, publish_day
            FROM poems
            WHERE publish_day = ?
            ORDER BY normalized_hash ASC, id ASC
            LIMIT ?
            """,
        (rs, rowNum) ->
            new Poem(
                rs.getLong("id"),
                rs.getString("content"),
                Instant.parse(rs.getString("created_at")),
                LocalDate.parse(rs.getString("publish_day"))),
        publishDay.toString(),
        limit);
  }

  public List<LocalDate> findPublishDaysWithPoems() {
    return jdbcTemplate.query(
        """
            SELECT DISTINCT publish_day
            FROM poems
            ORDER BY publish_day DESC
            """,
        (rs, rowNum) -> LocalDate.parse(rs.getString("publish_day")));
  }

  public int countByPublishDay(LocalDate publishDay) {
    Integer count =
        jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM poems WHERE publish_day = ?", Integer.class, publishDay.toString());
    return count == null ? 0 : count;
  }

  public boolean existsByNormalizedHashSince(String normalizedHash, Instant sinceInclusive) {
    Integer count =
        jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM poems WHERE normalized_hash = ? AND created_at >= ?",
            Integer.class,
            normalizedHash,
            sinceInclusive.toString());
    return count != null && count > 0;
  }
}
