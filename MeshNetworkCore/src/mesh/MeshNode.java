package mesh;

import mesh.crypto.CryptoUtils;
import mesh.crypto.EncryptedPayload;
import mesh.discovery.PeerDiscovery;
import mesh.discovery.PeerInfo;
import mesh.identity.DeviceIdentity;
import mesh.security.RevocationList;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.*;
import java.net.*;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.*;

public class MeshNode {

    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.out.println("Usage: java mesh.MeshNode <deviceName> <tcpPort> [httpApiPort] [backendUrl]");
            System.out.println("Example: java mesh.MeshNode Alex 9001 8081 http://localhost:8080");
            return;
        }
        String name = args[0];
        int tcpPort = Integer.parseInt(args[1]);
        int httpPort = args.length > 2 ? Integer.parseInt(args[2]) : tcpPort + 1000;
        String backendUrl = args.length > 3 ? args[3] : null;
        new MeshNode(name, tcpPort, httpPort, backendUrl).start();
    }

    private final DeviceIdentity identity;
    private final int tcpPort;
    private final int httpPort;
    private final String backendUrl;
    private final PeerDiscovery discovery;
    private final List<MessageRecord> history = Collections.synchronizedList(new ArrayList<>());
    private final Map<String, List<PendingMessage>> offlineQueue = new ConcurrentHashMap<>();
    private final Metrics metrics = new Metrics();

    public MeshNode(String name, int tcpPort, int httpPort, String backendUrl) throws Exception {
        this.identity = new DeviceIdentity(name);
        this.tcpPort = tcpPort;
        this.httpPort = httpPort;
        this.backendUrl = backendUrl;
        this.discovery = new PeerDiscovery(identity, tcpPort);
    }

    public void start() throws Exception {
        if (backendUrl != null) {
            RevocationList.configureBackend(backendUrl);
            registerWithBackend();
        }
        discovery.start();
        startTcpServer();
        startHttpApi();
        startQueueFlusher();
        System.out.println("\n=== " + identity.deviceName + " is online ===");
        System.out.println("TCP messaging port: " + tcpPort);
        System.out.println("Local API (Flutter app calls this): http://localhost:" + httpPort);
        System.out.println(backendUrl != null ? "Admin backend: " + backendUrl
                : "No backend configured (revocation is local only).");
        System.out.println("Commands: peers | send <name> <message> | revoke <name> | restore <name> | queue | quit\n");
        consoleLoop();
    }

    private void registerWithBackend() {
        try {
            HttpClient client = HttpClient.newHttpClient();
            String body = "{\"name\":\"" + identity.deviceName
                    + "\",\"fingerprint\":\"" + identity.fingerprint + "\"}";
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(backendUrl + "/api/devices/register"))
                    .timeout(Duration.ofSeconds(3))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body)).build();
            client.send(request, HttpResponse.BodyHandlers.ofString());
            System.out.println("[backend] Registered with admin backend at " + backendUrl);
        } catch (Exception e) {
            System.out.println("[backend] Could not reach backend — continuing without it.");
        }
    }

    private void startTcpServer() {
        Thread t = new Thread(() -> {
            try (ServerSocket server = new ServerSocket(tcpPort)) {
                while (true) handleIncoming(server.accept());
            } catch (Exception e) {
                System.out.println("[tcp] server error: " + e.getMessage());
            }
        });
        t.setDaemon(true);
        t.start();
    }

    private void handleIncoming(Socket socket) {
        new Thread(() -> {
            try (BufferedReader in = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8))) {
                String line = in.readLine();
                if (line == null) return;

                if (line.startsWith("ACK|")) {
                    String[] parts = line.split("\\|", 3);
                    System.out.println("[receipt] Delivery confirmed by " + parts[1] + " for " + parts[2]);
                    metrics.delivered++;
                    return;
                }

                if (line.startsWith("MSG|")) {
                    String[] parts = line.split("\\|", 4);
                    String fromName = parts[1];
                    String msgId = parts[2];
                    String payloadJson = parts[3];

                    if (RevocationList.load().contains(identity.deviceName)) {
                        System.out.println("[security] This device is revoked — ignoring traffic.");
                        return;
                    }
                    if (RevocationList.load().contains(fromName)) {
                        System.out.println("[security] Rejected message from revoked device: " + fromName);
                        return;
                    }

                    EncryptedPayload payload = EncryptedPayload.fromJson(payloadJson);
                    String plaintext = CryptoUtils.decrypt(payload, identity.keyPair.getPrivate());
                    System.out.println("\n[message] " + fromName + ": " + plaintext);
                    history.add(new MessageRecord("RECEIVED", fromName, plaintext, "DELIVERED"));
                    sendAck(fromName, msgId);
                    return;
                }

                if (line.startsWith("FILE|")) {
                    String[] parts = line.split("\\|", 5);
                    String fromName = parts[1];
                    String msgId = parts[2];
                    String fileName = parts[3];
                    String payloadJson = parts[4];

                    if (RevocationList.load().contains(identity.deviceName)) {
                        System.out.println("[security] This device is revoked — ignoring traffic.");
                        return;
                    }
                    if (RevocationList.load().contains(fromName)) {
                        System.out.println("[security] Rejected file from revoked device: " + fromName);
                        return;
                    }

                    EncryptedPayload payload = EncryptedPayload.fromJson(payloadJson);
                    String base64Data = CryptoUtils.decrypt(payload, identity.keyPair.getPrivate());
                    System.out.println("\n[file] Received '" + fileName + "' from " + fromName);

                    MessageRecord record = new MessageRecord("RECEIVED", fromName, "[file] " + fileName, "DELIVERED");
                    record.fileName = fileName;
                    record.fileData = base64Data;
                    history.add(record);
                    sendAck(fromName, msgId);
                }
            } catch (Exception e) {
                System.out.println("[tcp] failed to process message: " + e.getMessage());
            }
        }).start();
    }

    private void sendAck(String toName, String msgId) {
        PeerInfo peer = discovery.getPeers().get(toName);
        if (peer == null) return;
        try (Socket socket = new Socket(peer.host, peer.tcpPort)) {
            socket.getOutputStream().write(
                    ("ACK|" + identity.deviceName + "|" + msgId + "\n").getBytes(StandardCharsets.UTF_8));
        } catch (Exception ignored) {}
    }

    public String sendMessage(String toName, String text) {
        if (RevocationList.load().contains(identity.deviceName))
            return "BLOCKED: this device has been revoked by admin.";
        if (RevocationList.load().contains(toName)) {
            history.add(new MessageRecord("SENT", toName, text, "BLOCKED"));
            return "BLOCKED: " + toName + " has been revoked.";
        }

        String msgId = UUID.randomUUID().toString().substring(0, 8);
        PeerInfo peer = discovery.getPeers().get(toName);

        if (peer == null) {
            queueMessage(toName, text, msgId);
            history.add(new MessageRecord("SENT", toName, text, "QUEUED"));
            return "QUEUED: " + toName + " not reachable. Will auto-deliver when back in range.";
        }

        try {
            var publicKey = CryptoUtils.publicKeyFromBase64(peer.publicKeyBase64);
            EncryptedPayload payload = CryptoUtils.encrypt(text, publicKey);
            deliverOverTcp(peer, msgId, payload);
            history.add(new MessageRecord("SENT", toName, text, "DELIVERED"));
            metrics.sent++;
            return "SENT to " + toName + " (encrypted, id " + msgId + ")";
        } catch (Exception e) {
            queueMessage(toName, text, msgId);
            history.add(new MessageRecord("SENT", toName, text, "QUEUED"));
            return "QUEUED: delivery failed (" + e.getMessage() + "), will retry.";
        }
    }

    public String sendFile(String toName, String fileName, String base64Data) {
        if (RevocationList.load().contains(identity.deviceName))
            return "BLOCKED: this device has been revoked by admin.";
        if (RevocationList.load().contains(toName))
            return "BLOCKED: " + toName + " has been revoked.";

        String msgId = UUID.randomUUID().toString().substring(0, 8);
        PeerInfo peer = discovery.getPeers().get(toName);

        MessageRecord record = new MessageRecord("SENT", toName, "[file] " + fileName, "QUEUED");
        record.fileName = fileName;
        record.fileData = base64Data;

        if (peer == null) {
            offlineQueue.computeIfAbsent(toName, k -> new ArrayList<>())
                    .add(new PendingMessage(msgId, "FILE", base64Data, fileName));
            history.add(record);
            return "QUEUED: " + toName + " not reachable. File will auto-send when back in range.";
        }

        try {
            var publicKey = CryptoUtils.publicKeyFromBase64(peer.publicKeyBase64);
            EncryptedPayload payload = CryptoUtils.encrypt(base64Data, publicKey);
            deliverFileOverTcp(peer, msgId, fileName, payload);
            record.status = "DELIVERED";
            history.add(record);
            metrics.sent++;
            return "SENT file to " + toName;
        } catch (Exception e) {
            offlineQueue.computeIfAbsent(toName, k -> new ArrayList<>())
                    .add(new PendingMessage(msgId, "FILE", base64Data, fileName));
            record.status = "QUEUED";
            history.add(record);
            return "QUEUED: file delivery failed, will retry.";
        }
    }

    private void deliverOverTcp(PeerInfo peer, String msgId, EncryptedPayload payload) throws Exception {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(peer.host, peer.tcpPort), 2000);
            socket.getOutputStream().write(("MSG|" + identity.deviceName + "|" + msgId + "|"
                    + payload.toJson() + "\n").getBytes(StandardCharsets.UTF_8));
        }
    }

    private void deliverFileOverTcp(PeerInfo peer, String msgId, String fileName, EncryptedPayload payload) throws Exception {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(peer.host, peer.tcpPort), 3000);
            socket.getOutputStream().write(("FILE|" + identity.deviceName + "|" + msgId + "|" + fileName + "|"
                    + payload.toJson() + "\n").getBytes(StandardCharsets.UTF_8));
        }
    }

    private void queueMessage(String toName, String text, String msgId) {
        offlineQueue.computeIfAbsent(toName, k -> new ArrayList<>()).add(new PendingMessage(msgId, "TEXT", text, null));
        System.out.println("[queue] Message to " + toName + " queued offline.");
    }

    private void startQueueFlusher() {
        Executors.newSingleThreadScheduledExecutor().scheduleAtFixedRate(() -> {
            for (String peerName : new HashSet<>(offlineQueue.keySet())) {
                PeerInfo peer = discovery.getPeers().get(peerName);
                if (peer == null) continue;
                List<PendingMessage> pending = offlineQueue.remove(peerName);
                if (pending == null) continue;
                System.out.println("[reconnect] " + peerName + " is back — flushing "
                        + pending.size() + " queued item(s).");
                metrics.reconnections++;
                for (PendingMessage pm : pending) {
                    try {
                        var publicKey = CryptoUtils.publicKeyFromBase64(peer.publicKeyBase64);
                        EncryptedPayload payload = CryptoUtils.encrypt(pm.text, publicKey);
                        if ("FILE".equals(pm.kind)) {
                            deliverFileOverTcp(peer, pm.id, pm.fileName, payload);
                        } else {
                            deliverOverTcp(peer, pm.id, payload);
                        }
                        metrics.sent++;
                    } catch (Exception e) {
                        offlineQueue.computeIfAbsent(peerName, k -> new ArrayList<>()).add(pm);
                    }
                }
            }
        }, 3, 3, TimeUnit.SECONDS);
    }

    private void consoleLoop() throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
        String line;
        while ((line = reader.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            try {
                if (line.equals("peers")) {
                    if (discovery.getPeers().isEmpty()) System.out.println("No peers discovered yet.");
                    for (PeerInfo p : discovery.getPeers().values()) {
                        System.out.println(" - " + p.name + " @ " + p.host + ":" + p.tcpPort
                                + (RevocationList.load().contains(p.name) ? "  [REVOKED]" : ""));
                    }
                } else if (line.startsWith("send ")) {
                    String[] parts = line.split(" ", 3);
                    if (parts.length < 3) { System.out.println("Usage: send <name> <message>"); continue; }
                    System.out.println(sendMessage(parts[1], parts[2]));
                } else if (line.startsWith("revoke ")) {
                    RevocationList.revoke(line.split(" ", 2)[1]);
                    System.out.println("[admin] Revoked.");
                } else if (line.startsWith("restore ")) {
                    RevocationList.restore(line.split(" ", 2)[1]);
                    System.out.println("[admin] Restored.");
                } else if (line.equals("queue")) {
                    System.out.println(offlineQueue.isEmpty() ? "Queue is empty." : offlineQueue.toString());
                } else if (line.equals("quit")) {
                    System.exit(0);
                } else {
                    System.out.println("Try: peers | send <name> <msg> | revoke <name> | restore <name> | queue | quit");
                }
            } catch (Exception e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }

    private void startHttpApi() throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(httpPort), 0);

        server.createContext("/status", ex -> sendJson(ex,
                "{\"name\":\"" + identity.deviceName + "\",\"fingerprint\":\"" + identity.fingerprint
                        + "\",\"tcpPort\":" + tcpPort + ",\"revoked\":"
                        + RevocationList.load().contains(identity.deviceName) + "}"));

        server.createContext("/peers", ex -> {
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            for (PeerInfo p : discovery.getPeers().values()) {
                if (!first) sb.append(",");
                first = false;
                sb.append("{\"name\":\"").append(p.name).append("\",\"host\":\"").append(p.host)
                        .append("\",\"revoked\":").append(RevocationList.load().contains(p.name)).append("}");
            }
            sendJson(ex, sb.append("]").toString());
        });

        server.createContext("/messages", ex -> {
            StringBuilder sb = new StringBuilder("[");
            synchronized (history) {
                for (int i = 0; i < history.size(); i++) {
                    if (i > 0) sb.append(",");
                    sb.append(history.get(i).toJson());
                }
            }
            sendJson(ex, sb.append("]").toString());
        });

        server.createContext("/metrics", ex -> sendJson(ex,
                "{\"sent\":" + metrics.sent + ",\"delivered\":" + metrics.delivered
                        + ",\"reconnections\":" + metrics.reconnections
                        + ",\"queued\":" + offlineQueue.size() + "}"));

        server.createContext("/send", ex -> {
            if (!"POST".equals(ex.getRequestMethod())) { ex.sendResponseHeaders(405, -1); return; }
            String body = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            String result = sendMessage(EncryptedPayload.extract(body, "to"),
                    EncryptedPayload.extract(body, "text"));
            sendJson(ex, "{\"result\":\"" + result.replace("\"", "'") + "\"}");
        });

        server.createContext("/sendfile", ex -> {
            if (!"POST".equals(ex.getRequestMethod())) { ex.sendResponseHeaders(405, -1); return; }
            String body = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            String to = EncryptedPayload.extract(body, "to");
            String filename = EncryptedPayload.extract(body, "filename");
            String data = EncryptedPayload.extract(body, "data");
            String result = sendFile(to, filename, data);
            sendJson(ex, "{\"result\":\"" + result.replace("\"", "'") + "\"}");
        });

        server.setExecutor(Executors.newCachedThreadPool());
        server.start();
    }

    private void sendJson(HttpExchange ex, String json) throws IOException {
        ex.getResponseHeaders().set("Content-Type", "application/json");
        ex.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        ex.sendResponseHeaders(200, bytes.length);
        try (OutputStream os = ex.getResponseBody()) { os.write(bytes); }
    }

    static class PendingMessage {
        String id, kind, text, fileName;
        PendingMessage(String id, String kind, String text, String fileName) {
            this.id = id; this.kind = kind; this.text = text; this.fileName = fileName;
        }
    }

    static class Metrics { int sent = 0, delivered = 0, reconnections = 0; }

    static class MessageRecord {
        String direction, peer, text, status, fileName, fileData;
        long timestamp = System.currentTimeMillis();
        MessageRecord(String direction, String peer, String text, String status) {
            this.direction = direction; this.peer = peer; this.text = text; this.status = status;
        }
        String toJson() {
            StringBuilder sb = new StringBuilder();
            sb.append("{\"direction\":\"").append(direction).append("\",\"peer\":\"").append(peer)
                    .append("\",\"text\":\"").append(text == null ? "" : text.replace("\"", "'"))
                    .append("\",\"status\":\"").append(status).append("\",\"timestamp\":").append(timestamp);
            if (fileName != null) sb.append(",\"fileName\":\"").append(fileName.replace("\"", "'")).append("\"");
            if (fileData != null) sb.append(",\"fileData\":\"").append(fileData).append("\"");
            sb.append("}");
            return sb.toString();
        }
    }
}