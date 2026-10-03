package com.mesh.backend.model;

import jakarta.persistence.*;
import java.util.*;

@Entity
public class Room {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String membersCsv = "";

    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getMembersCsv() { return membersCsv; }
    public void setMembersCsv(String membersCsv) { this.membersCsv = membersCsv; }

    public List<String> getMembers() {
        if (membersCsv == null || membersCsv.isBlank()) return new ArrayList<>();
        return Arrays.asList(membersCsv.split(","));
    }
}