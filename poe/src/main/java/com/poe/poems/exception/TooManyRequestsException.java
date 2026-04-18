package com.poe.poems.exception;

import java.time.Instant;

public class TooManyRequestsException extends ApiException {

  private final Instant retryAt;

  public TooManyRequestsException(String code, String message, Instant retryAt) {
    super(code, message);
    this.retryAt = retryAt;
  }

  public Instant getRetryAt() {
    return retryAt;
  }
}
