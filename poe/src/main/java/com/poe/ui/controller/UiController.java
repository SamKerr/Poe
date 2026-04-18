package com.poe.ui.controller;

import com.poe.poems.dto.DailyFeedResponse;
import com.poe.poems.exception.ApiException;
import com.poe.poems.service.PoemService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.time.LocalDate;
import java.util.List;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class UiController {

  private final PoemService poemService;

  public UiController(PoemService poemService) {
    this.poemService = poemService;
  }

  @GetMapping("/")
  public String landing(Model model) {
    DailyFeedResponse feed = poemService.getDailyFeed();
    model.addAttribute("day", feed.day());
    model.addAttribute("poems", feed.items());
    model.addAttribute("count", feed.count());
    return "index";
  }

  @GetMapping("/history")
  public String history(Model model) {
    List<LocalDate> days = poemService.getPublishDaysWithPoems();
    model.addAttribute("days", days);
    return "history";
  }

  @GetMapping("/history/{day}")
  public String historyDay(@PathVariable String day, Model model, HttpServletResponse response) {
    try {
      LocalDate parsed = poemService.parseStrictDay(day);
      DailyFeedResponse feed = poemService.getDailyFeedByDay(parsed);
      model.addAttribute("day", feed.day());
      model.addAttribute("poems", feed.items());
      model.addAttribute("count", feed.count());
      return "history-day";
    } catch (ApiException ex) {
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      model.addAttribute("day", day);
      model.addAttribute("errorMessage", ex.getMessage());
      model.addAttribute("poems", List.of());
      model.addAttribute("count", 0);
      return "history-day";
    }
  }

  @GetMapping("/write")
  public String write(Model model) {
    populateWritePageState(model);
    return "write";
  }

  @PostMapping("/write")
  public String submitPoem(
      @RequestParam(name = "content", required = false) String content,
      HttpServletRequest request,
      HttpServletResponse response,
      Model model,
      RedirectAttributes redirectAttributes) {
    try {
      poemService.publish(content, extractSourceIp(request));
      redirectAttributes.addFlashAttribute("successMessage", "Poem posted.");
      return "redirect:/";
    } catch (ApiException ex) {
      response.setStatus(statusFor(ex.getCode()));
      model.addAttribute("content", content == null ? "" : content);
      model.addAttribute("errorCode", ex.getCode());
      model.addAttribute("errorMessage", ex.getMessage());
      populateWritePageState(model);
      return "write";
    }
  }

  private void populateWritePageState(Model model) {
    int todayCount = poemService.getTodayPoemCount();
    boolean canSubmit = poemService.isTodaySubmissionOpen();
    model.addAttribute("todayCount", todayCount);
    model.addAttribute("todayLimit", PoemService.DAILY_POEM_LIMIT);
    model.addAttribute("canSubmit", canSubmit);
  }

  private static int statusFor(String errorCode) {
    if ("RATE_LIMITED".equals(errorCode)) {
      return 429;
    }
    return HttpServletResponse.SC_BAD_REQUEST;
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
