import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5925';

  Future<List<Track>> fetchTracks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/tracks'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load tracks ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Track.fromJson(json)).toList();
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  String streamUrl(String trackId) => '$baseUrl/api/stream/$trackId';
}