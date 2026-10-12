package com.thesis.java_app.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.BatchPreparedStatementSetter;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.PreparedStatement;
import java.sql.SQLException;

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
        jdbcTemplate.execute("TRUNCATE TABLE data_a, data_b RESTART IDENTITY CASCADE");

        // SEEDING data_a TABLE
        jdbcTemplate.batchUpdate(
                "INSERT INTO data_a (name,value) VALUES (?, ?)",
                new BatchPreparedStatementSetter() {
                    @Override
                    public void setValues(PreparedStatement ps, int i) throws SQLException {
                        ps.setString(1, "Name " + (i + 1));
                        ps.setInt(2, (i + 1) * 10);
                    }

                    @Override
                    public int getBatchSize() {
                        return 10000;
                    }
                }
        );

        // SEEDING data_b TABLE
        jdbcTemplate.batchUpdate(
                "INSERT INTO data_b (data_a_id, title, description) VALUES (?, ?, ?)",
                new BatchPreparedStatementSetter() {
                    @Override
                    public void setValues(PreparedStatement ps, int i) throws SQLException {
                        int dataAId = (i / 4) + 1;
                        ps.setInt(1, dataAId);
                        ps.setString(2, "Title " + (i+1));
                        ps.setString(3, "Description " + (i + 1));
                    }

                    @Override
                    public int getBatchSize() {
                        return 40000;
                    }
                }
        );

        return ResponseEntity.ok("Database reset and seeded succes");
    }
}