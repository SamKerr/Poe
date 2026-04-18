package com.poe;

import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DbCheckController {

  private static final Logger log = LoggerFactory.getLogger(DbCheckController.class);

  private final JdbcTemplate jdbcTemplate;

  public DbCheckController(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @GetMapping("/")
  public Map<String, Object> root() {
    log.info("Handling GET /");
    Integer one = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
    log.info("GET / completed with dbSelect={}", one);
    return Map.of("status", "ok", "dbSelect", one);
  }

  @GetMapping("/users")
  public Object users() {
    log.info("Handling GET /users");
    Object result = jdbcTemplate.queryForList("SELECT id, name FROM demo_users ORDER BY id");
    log.info("GET /users completed");
    return result;
  }

  @GetMapping("/sqlite")
  public Map<String, Object> sqlite() {
    log.info("Handling GET /sqlite");
    Integer one = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
    log.info("GET /sqlite completed with sqliteSelect={}", one);
    return Map.of("status", "ok", "sqliteSelect", one);
  }

  @GetMapping("/sqlite/users")
  public Object sqliteUsers() {
    log.info("Handling GET /sqlite/users");
    Object result = jdbcTemplate.queryForList("SELECT id, title FROM demo_notes ORDER BY id");
    log.info("GET /sqlite/users completed");
    return result;
  }
}
