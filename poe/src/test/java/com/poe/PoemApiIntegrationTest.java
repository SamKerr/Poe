package com.poe;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
class PoemApiIntegrationTest {

  @Autowired private MockMvc mockMvc;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private ObjectMapper objectMapper;

  @BeforeEach
  void resetPoemsTable() {
    jdbcTemplate.update("DELETE FROM poems");
    jdbcTemplate.update("DELETE FROM sqlite_sequence WHERE name = 'poems'");
  }

  @Test
  void postPoemAcceptsOneCharacter() throws Exception {
    mockMvc
        .perform(
            post("/poems")
                .header("X-Forwarded-For", "198.51.100.1")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content":"a"}
                    """))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.id").isNumber())
        .andExpect(jsonPath("$.content").value("a"))
        .andExpect(jsonPath("$.createdAt").isString())
        .andExpect(jsonPath("$.publishDay").isString());
  }

  @Test
  void postPoemAcceptsTwoThousandCharacters() throws Exception {
    String content = "x".repeat(2000);

    mockMvc
        .perform(
            post("/poems")
                .header("X-Forwarded-For", "198.51.100.2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content":"%s"}
                    """
                    .formatted(content)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.content").value(content));
  }

  @Test
  void postPoemRejectsTwoThousandAndOneCharacters() throws Exception {
    String content = "x".repeat(2001);

    mockMvc
        .perform(
            post("/poems")
                .header("X-Forwarded-For", "198.51.100.3")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content":"%s"}
                    """
                    .formatted(content)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("CONTENT_TOO_LONG"));
  }

  @Test
  void postPoemRejectsMissingContent() throws Exception {
    mockMvc
        .perform(
            post("/poems")
                .header("X-Forwarded-For", "198.51.100.4")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("CONTENT_REQUIRED"));
  }

  @Test
  void postPoemRejectsBlankContentAfterTrim() throws Exception {
    mockMvc
        .perform(
            post("/poems")
                .header("X-Forwarded-For", "198.51.100.5")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content":"  \\n\\t  "}
                    """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("CONTENT_BLANK"));
  }

  @Test
  void postAndGetPoemReturnsNormalizedContent() throws Exception {
    MvcResult creationResult =
        mockMvc
            .perform(
                post("/poems")
                    .header("X-Forwarded-For", "198.51.100.6")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                        {"content":"  first line\\r\\nsecond line  "}
                        """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.content").value("first line\nsecond line"))
            .andReturn();

    long createdId = objectMapper.readTree(creationResult.getResponse().getContentAsString()).get("id").asLong();

    mockMvc
        .perform(get("/poems/{id}", createdId))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(createdId))
        .andExpect(jsonPath("$.content").value("first line\nsecond line"));
  }

  @Test
  void getPoemByIdReturnsNotFoundWhenMissing() throws Exception {
    mockMvc
        .perform(get("/poems/{id}", 9999))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("POEM_NOT_FOUND"));
  }

  @Test
  void postPoemRejectsDuplicateContentWithinConfiguredWindow() throws Exception {
    String sharedIp = "198.51.100.7";
    String body = """
        {"content":"same poem content"}
        """;

    mockMvc
        .perform(post("/poems").header("X-Forwarded-For", sharedIp).contentType(MediaType.APPLICATION_JSON).content(body))
        .andExpect(status().isCreated());

    mockMvc
        .perform(post("/poems").header("X-Forwarded-For", sharedIp).contentType(MediaType.APPLICATION_JSON).content(body))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("DUPLICATE_POEM"))
        .andExpect(jsonPath("$.error.message").value("Duplicate poem content was submitted recently"));
  }

  @Test
  void postPoemRejectsSixthRequestInTenMinuteWindowForSameIp() throws Exception {
    String sharedIp = "198.51.100.8";

    for (int i = 0; i < 5; i++) {
      String content = "unique poem " + i + "-" + UUID.randomUUID();
      mockMvc
          .perform(
              post("/poems")
                  .header("X-Forwarded-For", sharedIp)
                  .contentType(MediaType.APPLICATION_JSON)
                  .content("""
                      {"content":"%s"}
                      """
                      .formatted(content)))
          .andExpect(status().isCreated());
    }

    mockMvc
        .perform(
            post("/poems")
                .header("X-Forwarded-For", sharedIp)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content":"another unique poem"}
                    """))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("RATE_LIMITED"))
        .andExpect(jsonPath("$.error.message").value("Too many requests from this IP. Please try again later."))
        .andExpect(jsonPath("$.error.retryAt").isNotEmpty());
  }

  @Test
  void getDailyFeedIsDeterministicAndLimitedToTenItems() throws Exception {
    LocalDate todayUtc = LocalDate.now(ZoneOffset.UTC);
    Instant baseTime = Instant.parse("2026-01-01T00:00:00Z");

    for (int i = 0; i < 12; i++) {
      insertPoem("poem-" + i, todayUtc, baseTime.plusSeconds(i));
    }

    MvcResult first =
        mockMvc
            .perform(get("/feed/daily"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.day").value(todayUtc.toString()))
            .andExpect(jsonPath("$.limit").value(10))
            .andExpect(jsonPath("$.count").value(10))
            .andExpect(jsonPath("$.items.length()").value(10))
            .andReturn();

    MvcResult second =
        mockMvc
            .perform(get("/feed/daily"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.day").value(todayUtc.toString()))
            .andExpect(jsonPath("$.limit").value(10))
            .andExpect(jsonPath("$.count").value(10))
            .andExpect(jsonPath("$.items.length()").value(10))
            .andReturn();

    assertEquals(first.getResponse().getContentAsString(), second.getResponse().getContentAsString());
  }

  @Test
  void getDailyFeedDoesNotBackfillFromOtherDays() throws Exception {
    LocalDate todayUtc = LocalDate.now(ZoneOffset.UTC);
    LocalDate previousDay = todayUtc.minusDays(1);
    Instant baseTime = Instant.parse("2026-01-02T00:00:00Z");

    insertPoem("today-only-1", todayUtc, baseTime);
    insertPoem("today-only-2", todayUtc, baseTime.plusSeconds(1));

    for (int i = 0; i < 5; i++) {
      insertPoem("old-poem-" + i, previousDay, baseTime.plusSeconds(10 + i));
    }

    mockMvc
        .perform(get("/feed/daily"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.day").value(todayUtc.toString()))
        .andExpect(jsonPath("$.limit").value(10))
        .andExpect(jsonPath("$.count").value(2))
        .andExpect(jsonPath("$.items.length()").value(2));
  }

  @Test
  void getDailyFeedByDayRejectsInvalidDayFormat() throws Exception {
    mockMvc
        .perform(get("/feed/daily/{day}", "2026-2-01"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("INVALID_DAY_FORMAT"))
        .andExpect(jsonPath("$.error.message").value("day must be in YYYY-MM-DD format"));

    mockMvc
        .perform(get("/feed/daily/{day}", "2026-02-31"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("INVALID_DAY_FORMAT"))
        .andExpect(jsonPath("$.error.message").value("day must be in YYYY-MM-DD format"));
  }

  @Test
  void getDailyFeedByDayReturnsEmptyItemsForValidDayWithoutPoems() throws Exception {
    String targetDay = "2026-03-15";

    mockMvc
        .perform(get("/feed/daily/{day}", targetDay))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.day").value(targetDay))
        .andExpect(jsonPath("$.limit").value(10))
        .andExpect(jsonPath("$.count").value(0))
        .andExpect(jsonPath("$.items.length()").value(0))
        .andExpect(content().json("""
            {"day":"2026-03-15","count":0,"limit":10,"items":[]}
            """));
  }

  private void insertPoem(String content, LocalDate publishDay, Instant createdAt) {
    jdbcTemplate.update(
        "INSERT INTO poems (content, normalized_hash, created_at, publish_day) VALUES (?, ?, ?, ?)",
        content,
        sha256Hex(content),
        createdAt.toString(),
        publishDay.toString());
  }

  private String sha256Hex(String value) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(hash);
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException("SHA-256 is unavailable", e);
    }
  }
}
