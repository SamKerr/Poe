package com.poe.poems;

public class BadRequestException extends ApiException {

  public BadRequestException(String code, String message) {
    super(code, message);
  }
}
