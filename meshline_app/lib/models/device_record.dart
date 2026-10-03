class DeviceRecord {
  final int id;
  final String name;
  final String fingerprint;
  final bool revoked;
  DeviceRecord({required this.id, required this.name,
    required this.fingerprint, required this.revoked});
  factory DeviceRecord.fromJson(Map<String, dynamic> json) => DeviceRecord(
    id: json['id'],
    name: json['name'] ?? '',
    fingerprint: json['fingerprint'] ?? '',
    revoked: json['revoked'] ?? false,
  );
}