class MeshMessage {
  final String direction;
  final String peer;
  final String text;
  final String status;
  final int timestamp;
  final String? fileName;
  final String? fileData;

  MeshMessage({
    required this.direction,
    required this.peer,
    required this.text,
    required this.status,
    required this.timestamp,
    this.fileName,
    this.fileData,
  });

  factory MeshMessage.fromJson(Map<String, dynamic> json) => MeshMessage(
    direction: json['direction'] ?? '',
    peer: json['peer'] ?? '',
    text: json['text'] ?? '',
    status: json['status'] ?? '',
    timestamp: json['timestamp'] ?? 0,
    fileName: json['fileName'],
    fileData: json['fileData'],
  );
}