package com.thesis.java_app.repository;

import com.thesis.java_app.entity.DataA;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface DataARepository extends JpaRepository<DataA, Long> {
    @Query("SELECT a FROM DataA a LEFT JOIN FETCH a.dataBList WHERE a.id = :id")
    Optional<DataA> findByIdWithDataB(@Param("id") Long id);
}
