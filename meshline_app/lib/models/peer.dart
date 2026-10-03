class Peer {
  final String name;
  final String host;
  final bool revoked;
  Peer({required this.name, required this.host, required this.revoked});
  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
    name: json['name'] ?? '',
    host: json['host'] ?? '',
    revoked: json['revoked'] ?? false,
  );
}