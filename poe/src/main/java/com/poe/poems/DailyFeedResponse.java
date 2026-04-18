package com.poe.poems;

import java.time.LocalDate;
import java.util.List;

public record DailyFeedResponse(LocalDate day, int count, int limit, List<PoemResponse> items) {

  public static DailyFeedResponse from(LocalDate day, int limit, List<Poem> poems) {
    List<PoemResponse> feedItems = poems.stream().map(PoemResponse::from).toList();
    return new DailyFeedResponse(day, feedItems.size(), limit, feedItems);
  }
}
