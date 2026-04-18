package com.poe.poems.service;

import com.poe.poems.dto.DailyFeedResponse;
import com.poe.poems.exception.BadRequestException;
import com.poe.poems.exception.NotFoundException;
import com.poe.poems.exception.TooManyRequestsException;
import com.poe.poems.model.Poem;
import com.poe.poems.repository.PoemRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HexFormat;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class PoemService {

  private static final int MAX_CONTENT_LENGTH = 2000;
  public static final int DAILY_FEED_LIMIT = 10;
  private final PoemRepository poemRepository;
  private final int rateLimitMaxRequests;
  private final Duration rateLimitWindow;
  private final Duration duplicateWindow;
  private final ConcurrentHashMap<String, Deque<Instant>> requestTimesByIp = new ConcurrentHashMap<>();

  public PoemService(
      PoemRepository poemRepository,
      @Value("${poems.guardrails.rate-limit.max-requests}") int rateLimitMaxRequests,
      @Value("${poems.guardrails.rate-limit.window}") Duration rateLimitWindow,
      @Value("${poems.guardrails.duplicate-window}") Duration duplicateWindow) {
    this.poemRepository = poemRepository;
    this.rateLimitMaxRequests = rateLimitMaxRequests;
    this.rateLimitWindow = rateLimitWindow;
    this.duplicateWindow = duplicateWindow;
  }

  public Poem publish(String content, String sourceIp) {
    String normalizedContent = normalizeAndValidate(content);
    Instant createdAt = Instant.now();
    LocalDate publishDay = LocalDate.now(ZoneOffset.UTC);
    String normalizedHash = sha256Hex(normalizedContent);
    enforceRateLimit(sourceIp, createdAt);
    enforceDuplicateGuard(normalizedHash, createdAt);
    long poemId = poemRepository.insertPoem(normalizedContent, normalizedHash, createdAt, publishDay);

    return poemRepository
        .findById(poemId)
        .orElseThrow(() -> new IllegalStateException("Created poem could not be loaded"));
  }

  public Poem getById(long id) {
    return poemRepository
        .findById(id)
        .orElseThrow(() -> new NotFoundException("POEM_NOT_FOUND", "Poem not found"));
  }

  public DailyFeedResponse getDailyFeed() {
    return getDailyFeedByDay(LocalDate.now(ZoneOffset.UTC));
  }

  public DailyFeedResponse getDailyFeedByDay(LocalDate day) {
    List<Poem> poems = poemRepository.findFeedByPublishDay(day, DAILY_FEED_LIMIT);
    return DailyFeedResponse.from(day, DAILY_FEED_LIMIT, poems);
  }

  public LocalDate parseStrictDay(String day) {
    if (day == null || !day.matches("^\\d{4}-\\d{2}-\\d{2}$")) {
      throw new BadRequestException("INVALID_DAY_FORMAT", "day must be in YYYY-MM-DD format");
    }

    try {
      return LocalDate.parse(day);
    } catch (DateTimeParseException ex) {
      throw new BadRequestException("INVALID_DAY_FORMAT", "day must be in YYYY-MM-DD format");
    }
  }

  public List<LocalDate> getPublishDaysWithPoems() {
    return poemRepository.findPublishDaysWithPoems();
  }

  private String normalizeAndValidate(String content) {
    if (content == null) {
      throw new BadRequestException("CONTENT_REQUIRED", "content is required");
    }

    String normalized = content.replace("\r\n", "\n").replace('\r', '\n').strip();

    if (normalized.isEmpty()) {
      throw new BadRequestException("CONTENT_BLANK", "content must not be blank");
    }

    if (normalized.length() > MAX_CONTENT_LENGTH) {
      throw new BadRequestException(
          "CONTENT_TOO_LONG", "content must be at most " + MAX_CONTENT_LENGTH + " characters");
    }

    return normalized;
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

  private void enforceRateLimit(String sourceIp, Instant now) {
    Instant windowStart = now.minus(rateLimitWindow);
    String key = sourceIp == null || sourceIp.isBlank() ? "unknown" : sourceIp;
    Deque<Instant> timestamps = requestTimesByIp.computeIfAbsent(key, ignored -> new ArrayDeque<>());
    synchronized (timestamps) {
      while (!timestamps.isEmpty() && timestamps.peekFirst().isBefore(windowStart)) {
        timestamps.removeFirst();
      }
      if (timestamps.size() >= rateLimitMaxRequests) {
        Instant retryAt = timestamps.peekFirst().plus(rateLimitWindow);
        throw new TooManyRequestsException(
            "RATE_LIMITED",
            "Too many requests from this IP. Please try again later.",
            retryAt);
      }
      timestamps.addLast(now);
    }
  }

  private void enforceDuplicateGuard(String normalizedHash, Instant now) {
    Instant windowStart = now.minus(duplicateWindow);
    if (poemRepository.existsByNormalizedHashSince(normalizedHash, windowStart)) {
      throw new BadRequestException(
          "DUPLICATE_POEM", "Duplicate poem content was submitted recently");
    }
  }
}
