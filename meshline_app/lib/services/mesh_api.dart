import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/peer.dart';
import '../models/mesh_message.dart';

class MeshApi {
  final String baseUrl;
  MeshApi(this.baseUrl);

  Future<Map<String, dynamic>> getStatus() async {
    final res = await http.get(Uri.parse('$baseUrl/status')).timeout(const Duration(seconds: 3));
    return jsonDecode(res.body);
  }

  Future<List<Peer>> getPeers() async {
    final res = await http.get(Uri.parse('$baseUrl/peers')).timeout(const Duration(seconds: 3));
    final List data = jsonDecode(res.body);
    return data.map((e) => Peer.fromJson(e)).toList();
  }

  Future<List<MeshMessage>> getMessages() async {
    final res = await http.get(Uri.parse('$baseUrl/messages')).timeout(const Duration(seconds: 3));
    final List data = jsonDecode(res.body);
    return data.map((e) => MeshMessage.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getMetrics() async {
    final res = await http.get(Uri.parse('$baseUrl/metrics')).timeout(const Duration(seconds: 3));
    return jsonDecode(res.body);
  }

  Future<String> sendMessage(String to, String text) async {
    final res = await http
        .post(Uri.parse('$baseUrl/send'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'to': to, 'text': text}))
        .timeout(const Duration(seconds: 3));
    return jsonDecode(res.body)['result'] ?? 'unknown';
  }

  Future<String> sendFile(String to, String filename, String base64Data) async {
    final res = await http
        .post(Uri.parse('$baseUrl/sendfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'to': to, 'filename': filename, 'data': base64Data}))
        .timeout(const Duration(seconds: 15));
    return jsonDecode(res.body)['result'] ?? 'unknown';
  }
}