import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_record.dart';

class BackendApi {
  final String baseUrl;
  BackendApi(this.baseUrl);

  Future<List<DeviceRecord>> getDevices() async {
    final res = await http.get(Uri.parse('$baseUrl/api/devices'))
        .timeout(const Duration(seconds: 3));
    final List data = jsonDecode(res.body);
    return data.map((e) => DeviceRecord.fromJson(e)).toList();
  }

  Future<void> revoke(int id) async {
    await http.post(Uri.parse('$baseUrl/api/devices/$id/revoke'))
        .timeout(const Duration(seconds: 3));
  }

  Future<void> restore(int id) async {
    await http.post(Uri.parse('$baseUrl/api/devices/$id/restore'))
        .timeout(const Duration(seconds: 3));
  }
}