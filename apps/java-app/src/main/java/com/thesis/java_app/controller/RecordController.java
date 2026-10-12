package com.thesis.java_app.controller;

import com.thesis.java_app.entity.DataA;
import com.thesis.java_app.entity.DataB;
import com.thesis.java_app.repository.DataARepository;
import jakarta.transaction.Transactional;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
public class RecordController {

    private final DataARepository dataARepository;

    public RecordController(DataARepository dataARepository) {
        this.dataARepository = dataARepository;
    }

    // CPU & VThreads
    @GetMapping("/compute")
    public ResponseEntity<Long> compute(@RequestParam(defaultValue = "50") int n) {
        return ResponseEntity.ok(fibonacci(n));
    }

    private long fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

    // IO, RAM, ORM
    @GetMapping("/records/{id}")
    public ResponseEntity<DataA> getRecord(@PathVariable Long id) {
        return dataARepository.findByIdWithDataB(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // Connection pool, Transaction duration
    @PostMapping("/records")
    @Transactional
    public ResponseEntity<DataA> createRecord() {
        DataA parent = new DataA("POST TEST", 100);

        parent.getDataBList().add(new DataB(parent, "TITLE 1", "DESCRIPTION 1"));
        parent.getDataBList().add(new DataB(parent, "TITLE 2", "DESCRIPTION 2"));
        parent.getDataBList().add(new DataB(parent, "TITLE 3", "DESCRIPTION 3"));
        parent.getDataBList().add(new DataB(parent, "TITLE 4", "DESCRIPTION 4"));

        DataA saved = dataARepository.save(parent);
        return ResponseEntity.ok(saved);
    }
}
