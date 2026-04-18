package com.poe.poems;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PoemController {

  private final PoemService poemService;

  public PoemController(PoemService poemService) {
    this.poemService = poemService;
  }

  @PostMapping("/poems")
  public ResponseEntity<PoemResponse> createPoem(
      @RequestBody PublishPoemRequest request, HttpServletRequest servletRequest) {
    String content = request == null ? null : request.content();
    Poem createdPoem = poemService.publish(content, extractSourceIp(servletRequest));
    return ResponseEntity.status(HttpStatus.CREATED).body(PoemResponse.from(createdPoem));
  }

  @GetMapping("/poems/{id}")
  public PoemResponse getPoemById(@PathVariable long id) {
    return PoemResponse.from(poemService.getById(id));
  }

  @GetMapping("/feed/daily")
  public DailyFeedResponse getDailyFeed() {
    return poemService.getDailyFeed();
  }

  @GetMapping("/feed/daily/{day}")
  public DailyFeedResponse getDailyFeedByDay(@PathVariable String day) {
    return poemService.getDailyFeedByDay(poemService.parseStrictDay(day));
  }

  private String extractSourceIp(HttpServletRequest request) {
    String forwardedFor = request.getHeader("X-Forwarded-For");
    if (forwardedFor != null && !forwardedFor.isBlank()) {
      String firstIp = forwardedFor.split(",")[0].trim();
      if (!firstIp.isEmpty()) {
        return firstIp;
      }
    }
    String remoteAddress = request.getRemoteAddr();
    return remoteAddress == null || remoteAddress.isBlank() ? "unknown" : remoteAddress;
  }
}
