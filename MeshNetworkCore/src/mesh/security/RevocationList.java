package mesh.security;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.*;
import java.time.Duration;
import java.util.*;

public class RevocationList {
    private static final Path CACHE_FILE = Paths.get("revoked_cache.txt");
    private static final Path LOCAL_FILE = Paths.get("revoked_local.txt");
    private static String backendUrl = null;

    public static void configureBackend(String url) { backendUrl = url; }

    public static Set<String> load() {
        Set<String> result = new HashSet<>();

        if (backendUrl != null) {
            try {
                HttpClient client = HttpClient.newBuilder()
                        .connectTimeout(Duration.ofMillis(1200)).build();
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(backendUrl + "/api/devices/revoked-names"))
                        .timeout(Duration.ofMillis(1200)).GET().build();
                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                Set<String> fromBackend = parseJsonArray(response.body());
                Files.write(CACHE_FILE, fromBackend);
                result.addAll(fromBackend);
            } catch (Exception e) {
                result.addAll(readLines(CACHE_FILE)); // offline — use last known list
            }
        } else {
            result.addAll(readLines(CACHE_FILE));
        }

        result.addAll(readLines(LOCAL_FILE)); // console revoke commands always apply
        return result;
    }

    public static void revoke(String deviceName) throws Exception {
        Set<String> set = readLines(LOCAL_FILE);
        set.add(deviceName);
        Files.write(LOCAL_FILE, set);
    }

    public static void restore(String deviceName) throws Exception {
        Set<String> set = readLines(LOCAL_FILE);
        set.remove(deviceName);
        Files.write(LOCAL_FILE, set);
    }

    private static Set<String> readLines(Path file) {
        try {
            if (!Files.exists(file)) return new HashSet<>();
            Set<String> set = new HashSet<>();
            for (String line : Files.readAllLines(file)) if (!line.isBlank()) set.add(line.trim());
            return set;
        } catch (Exception e) { return new HashSet<>(); }
    }

    private static Set<String> parseJsonArray(String json) {
        Set<String> set = new HashSet<>();
        if (json == null || json.trim().length() < 2) return set;
        String body = json.trim();
        body = body.substring(1, body.length() - 1);
        for (String part : body.split(",")) {
            String cleaned = part.replace("\"", "").trim();
            if (!cleaned.isEmpty()) set.add(cleaned);
        }
        return set;
    }
}