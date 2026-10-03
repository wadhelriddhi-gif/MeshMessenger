package com.mesh.backend.controller;

import com.mesh.backend.model.Device;
import com.mesh.backend.repo.DeviceRepository;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/devices")
@CrossOrigin(origins = "*")
public class DeviceController {

    private final DeviceRepository repo;
    public DeviceController(DeviceRepository repo) { this.repo = repo; }

    @GetMapping
    public List<Device> listAll() { return repo.findAll(); }

    @PostMapping("/register")
    public Device register(@RequestBody Map<String, String> body) {
        Device d = repo.findByName(body.get("name")).orElseGet(Device::new);
        d.setName(body.get("name"));
        d.setFingerprint(body.get("fingerprint"));
        return repo.save(d);
    }

    @PostMapping("/{id}/revoke")
    public Device revoke(@PathVariable Long id) {
        Device d = repo.findById(id).orElseThrow();
        d.setRevoked(true);
        return repo.save(d);
    }

    @PostMapping("/{id}/restore")
    public Device restore(@PathVariable Long id) {
        Device d = repo.findById(id).orElseThrow();
        d.setRevoked(false);
        return repo.save(d);
    }

    @GetMapping("/revoked-names")
    public List<String> revokedNames() {
        List<String> names = new ArrayList<>();
        for (Device d : repo.findAll()) if (d.isRevoked()) names.add(d.getName());
        return names;
    }
}