package com.thesis.java_app.entity;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "data_a")
public class DataA {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Integer value;

    @OneToMany(mappedBy = "dataA", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DataB> dataBList = new ArrayList<>();

    public DataA(String name, Integer value) {
        this.name = name;
        this.value = value;
    }

    public DataA() {}

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Integer getValue() {
        return value;
    }

    public void setValue(Integer value) {
        this.value = value;
    }

    public List<DataB> getDataBList() {
        return dataBList;
    }

    public void setDataBList(List<DataB> dataBList) {
        this.dataBList = dataBList;
    }
}
