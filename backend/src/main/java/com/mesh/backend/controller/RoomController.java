package com.mesh.backend.controller;

import com.mesh.backend.model.Room;
import com.mesh.backend.repo.RoomRepository;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/rooms")
@CrossOrigin(origins = "*")
public class RoomController {
    private final RoomRepository repo;
    public RoomController(RoomRepository repo) { this.repo = repo; }

    @GetMapping
    public List<Room> listAll() { return repo.findAll(); }

    @PostMapping
    public Room create(@RequestBody Map<String, String> body) {
        Room r = new Room();
        r.setName(body.get("name"));
        r.setMembersCsv(body.getOrDefault("members", ""));
        return repo.save(r);
    }
}