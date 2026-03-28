import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  Future<dynamic> get(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: _headers(token),
    );
    return _parse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {String? token}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _parse(http.Response response) {
    final data = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data is Map<String, dynamic> ? data['message'] ?? 'Request failed' : 'Request failed');
    }

    return data;
  }
}
