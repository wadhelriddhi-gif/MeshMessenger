package mesh.discovery;

import mesh.identity.DeviceIdentity;
import mesh.crypto.CryptoUtils;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;

public class PeerDiscovery {
    private static final int DISCOVERY_PORT = 8888;
    private static final int STALE_MS = 8000; // no word in 8s = treat as out of range

    private final DeviceIdentity identity;
    private final int myTcpPort;
    private final Map<String, PeerInfo> peers = new ConcurrentHashMap<>();
    private DatagramSocket socket;

    public PeerDiscovery(DeviceIdentity identity, int myTcpPort) {
        this.identity = identity;
        this.myTcpPort = myTcpPort;
    }

    public void start() throws Exception {
        socket = new DatagramSocket(null);
        socket.setReuseAddress(true);
        socket.bind(new java.net.InetSocketAddress(DISCOVERY_PORT));
        socket.setBroadcast(true);

        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
        scheduler.scheduleAtFixedRate(this::broadcastPresence, 0, 2, TimeUnit.SECONDS);
        scheduler.scheduleAtFixedRate(this::pruneStalePeers, 3, 3, TimeUnit.SECONDS);

        Thread listener = new Thread(this::listenLoop);
        listener.setDaemon(true);
        listener.start();
    }

    private void broadcastPresence() {
        try {
            String pubKeyB64 = CryptoUtils.publicKeyToBase64(identity.keyPair.getPublic());
            String msg = "MESHDISCOVER|" + identity.deviceName + "|" + myTcpPort + "|" + pubKeyB64;
            byte[] data = msg.getBytes("UTF-8");
            socket.send(new DatagramPacket(data, data.length,
                    InetAddress.getByName("255.255.255.255"), DISCOVERY_PORT));
        } catch (Exception e) {
            // If this fails we're just isolated right now — that IS the outage scenario.
        }
    }

    private void listenLoop() {
        byte[] buf = new byte[8192];
        while (true) {
            try {
                DatagramPacket packet = new DatagramPacket(buf, buf.length);
                socket.receive(packet);
                String msg = new String(packet.getData(), 0, packet.getLength(), "UTF-8");
                if (!msg.startsWith("MESHDISCOVER|")) continue;

                String[] parts = msg.split("\\|");
                String name = parts[1];
                if (name.equals(identity.deviceName)) continue;

                PeerInfo peer = peers.computeIfAbsent(name, n -> new PeerInfo());
                boolean wasNew = peer.host == null;
                peer.name = name;
                peer.host = packet.getAddress().getHostAddress();
                peer.tcpPort = Integer.parseInt(parts[2]);
                peer.publicKeyBase64 = parts[3];
                peer.lastSeen = System.currentTimeMillis();
                if (wasNew) System.out.println("[discovery] Found new peer: " + name
                        + " at " + peer.host + ":" + peer.tcpPort);
            } catch (Exception ignored) {}
        }
    }

    private void pruneStalePeers() {
        long now = System.currentTimeMillis();
        for (Iterator<Map.Entry<String, PeerInfo>> it = peers.entrySet().iterator(); it.hasNext(); ) {
            Map.Entry<String, PeerInfo> e = it.next();
            if (now - e.getValue().lastSeen > STALE_MS) {
                System.out.println("[discovery] Lost contact with " + e.getKey() + " (out of range / offline)");
                it.remove();
            }
        }
    }

    public Map<String, PeerInfo> getPeers() { return peers; }
}