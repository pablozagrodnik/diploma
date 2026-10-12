package com.thesis.java_app.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "data_b")
public class DataB {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    public DataB(DataA dataA, String title, String description) {
        this.dataA = dataA;
        this.title = title;
        this.description = description;
    }

    public DataB() {}


    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public DataA getDataA() {
        return dataA;
    }

    public void setDataA(DataA dataA) {
        this.dataA = dataA;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "data_a_id", nullable = false)
    @JsonIgnore
    private DataA dataA;

    @Column(nullable = false, length = 50)
    private String title;

    @Column(nullable = false)
    private String description;


}
