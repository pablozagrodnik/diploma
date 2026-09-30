package com.thesis.java_app.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SystemController {

    private final JdbcTemplate jdbcTemplate;

    public SystemController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("OK");
    }

    @PostMapping("/reset")
    public ResponseEntity<String> resetDatabase() {
        // TRUNCATE TABLE
        Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
        return ResponseEntity.ok("Database reset success, result - " + result);
    }
}