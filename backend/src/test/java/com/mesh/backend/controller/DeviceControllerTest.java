package com.mesh.backend.controller;

import com.mesh.backend.repo.DeviceRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.DEFINED_PORT)
class DeviceControllerTest {

    @Autowired
    private DeviceRepository repo;

    private final HttpClient client = HttpClient.newHttpClient();
    private static final String BASE = "http://localhost:8080";

    private HttpResponse<String> post(String path, String jsonBody) throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE + path))
                .header("Content-Type", "application/json")
                .POST(jsonBody == null ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofString(jsonBody))
                .build();
        return client.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> get(String path) throws Exception {
        HttpRequest request = HttpRequest.newBuilder().uri(URI.create(BASE + path)).GET().build();
        return client.send(request, HttpResponse.BodyHandlers.ofString());
    }

    @Test
    void registerThenListWorks() throws Exception {
        HttpResponse<String> registerResponse = post("/api/devices/register",
                "{\"name\":\"TestDevice\",\"fingerprint\":\"AA:BB:CC\"}");
        assertEquals(200, registerResponse.statusCode());

        HttpResponse<String> listResponse = get("/api/devices");
        assertEquals(200, listResponse.statusCode());
        assertTrue(listResponse.body().contains("TestDevice"));
    }

    @Test
    void revokedDeviceAppearsInList() throws Exception {
        post("/api/devices/register", "{\"name\":\"RevokeMe\",\"fingerprint\":\"DD:EE:FF\"}");

        Long id = repo.findByName("RevokeMe").orElseThrow().getId();

        HttpResponse<String> revokeResponse = post("/api/devices/" + id + "/revoke", null);
        assertEquals(200, revokeResponse.statusCode());

        HttpResponse<String> revokedListResponse = get("/api/devices/revoked-names");
        assertTrue(revokedListResponse.body().contains("RevokeMe"));
    }
}