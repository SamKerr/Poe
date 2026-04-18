package com.poe.poems;

import java.time.Instant;

public record ErrorResponse(ErrorDetail error) {

  public static ErrorResponse from(ApiException ex) {
    if (ex instanceof TooManyRequestsException tooManyRequestsException) {
      return new ErrorResponse(
          new ErrorDetail(
              tooManyRequestsException.getCode(),
              tooManyRequestsException.getMessage(),
              tooManyRequestsException.getRetryAt()));
    }
    return new ErrorResponse(new ErrorDetail(ex.getCode(), ex.getMessage(), null));
  }

  public record ErrorDetail(String code, String message, Instant retryAt) {}
}
