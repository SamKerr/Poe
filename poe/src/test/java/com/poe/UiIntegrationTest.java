package com.poe;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.HexFormat;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
class UiIntegrationTest {

  @Autowired private MockMvc mockMvc;
  @Autowired private JdbcTemplate jdbcTemplate;

  @BeforeEach
  void resetPoemsTable() {
    jdbcTemplate.update("DELETE FROM poems");
    jdbcTemplate.update("DELETE FROM sqlite_sequence WHERE name = 'poems'");
  }

  @Test
  void landingPageRendersTodaysPoemsOnly() throws Exception {
    LocalDate today = LocalDate.now(ZoneOffset.UTC);
    LocalDate yesterday = today.minusDays(1);
    Instant baseTime = Instant.parse("2026-05-01T00:00:00Z");
    insertPoem("today poem", today, baseTime.plusSeconds(1));
    insertPoem("old poem", yesterday, baseTime);

    mockMvc
        .perform(get("/"))
        .andExpect(status().isOk())
        .andExpect(content().string(org.hamcrest.Matchers.containsString("Today's Poems")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("today poem")))
        .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("old poem"))));
  }

  @Test
  void historyPageListsOnlyDaysWithPoemsNewestFirst() throws Exception {
    Instant baseTime = Instant.parse("2026-05-01T00:00:00Z");
    insertPoem("poem one", LocalDate.parse("2026-05-01"), baseTime);
    insertPoem("poem two", LocalDate.parse("2026-05-03"), baseTime.plusSeconds(1));
    insertPoem("poem three", LocalDate.parse("2026-05-02"), baseTime.plusSeconds(2));

    MvcResult historyResult =
        mockMvc
        .perform(get("/history"))
        .andExpect(status().isOk())
        .andExpect(content().string(org.hamcrest.Matchers.containsString("/history/2026-05-03")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("/history/2026-05-02")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("/history/2026-05-01")))
        .andReturn();

    String html = historyResult.getResponse().getContentAsString();
    int day03 = html.indexOf("/history/2026-05-03");
    int day02 = html.indexOf("/history/2026-05-02");
    int day01 = html.indexOf("/history/2026-05-01");
    assertTrue(day03 < day02 && day02 < day01, "history days should render newest-first");
  }

  @Test
  void historyDayRendersPoemsForRequestedDay() throws Exception {
    Instant baseTime = Instant.parse("2026-05-01T00:00:00Z");
    insertPoem("day poem", LocalDate.parse("2026-05-03"), baseTime);
    insertPoem("other day poem", LocalDate.parse("2026-05-02"), baseTime.plusSeconds(1));

    mockMvc
        .perform(get("/history/2026-05-03"))
        .andExpect(status().isOk())
        .andExpect(content().string(org.hamcrest.Matchers.containsString("Poems for 2026-05-03")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("day poem")))
        .andExpect(
            content()
                .string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("other day poem"))));
  }

  @Test
  void historyDayInvalidFormatShowsError() throws Exception {
    mockMvc
        .perform(get("/history/2026-2-2"))
        .andExpect(status().isBadRequest())
        .andExpect(content().string(org.hamcrest.Matchers.containsString("day must be in YYYY-MM-DD format")));
  }

  @Test
  void writePageSubmitSuccessRedirectsHome() throws Exception {
    mockMvc
        .perform(post("/write").header("X-Forwarded-For", "203.0.113.10").param("content", "a new poem"))
        .andExpect(status().is3xxRedirection())
        .andExpect(redirectedUrl("/"));
  }

  @Test
  void writePageValidationErrorShowsMessageAndPreservesInput() throws Exception {
    mockMvc
        .perform(post("/write").header("X-Forwarded-For", "203.0.113.11").param("content", "   "))
        .andExpect(status().isBadRequest())
        .andExpect(content().string(org.hamcrest.Matchers.containsString("content must not be blank")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("<textarea")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("   ")));
  }

  @Test
  void writePageDisablesSubmissionWhenDailyLimitReached() throws Exception {
    LocalDate today = LocalDate.now(ZoneOffset.UTC);
    Instant baseTime = Instant.parse("2026-06-02T00:00:00Z");
    for (int i = 0; i < 30; i++) {
      insertPoem("today-poem-" + i, today, baseTime.plusSeconds(i));
    }

    mockMvc
        .perform(get("/write"))
        .andExpect(status().isOk())
        .andExpect(content().string(org.hamcrest.Matchers.containsString("Today's submissions:")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString(">30 / 30<")))
        .andExpect(
            content()
                .string(
                    org.hamcrest.Matchers.containsString(
                        "There have already been 30 poems today, so can't submit any more today.")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("button type=\"submit\" disabled")));
  }

  @Test
  void writePageSubmitWhenDailyLimitReachedShowsError() throws Exception {
    LocalDate today = LocalDate.now(ZoneOffset.UTC);
    Instant baseTime = Instant.parse("2026-06-03T00:00:00Z");
    for (int i = 0; i < 30; i++) {
      insertPoem("limit-poem-" + i, today, baseTime.plusSeconds(i));
    }

    mockMvc
        .perform(post("/write").header("X-Forwarded-For", "203.0.113.12").param("content", "one more poem"))
        .andExpect(status().isBadRequest())
        .andExpect(
            content()
                .string(org.hamcrest.Matchers.containsString("There are already 30 poems today. No more submissions today.")))
        .andExpect(content().string(org.hamcrest.Matchers.containsString("button type=\"submit\" disabled")));
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
