import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://medivault-xi-two.vercel.app/api/v1';

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    return response;
  }

  Future<http.Response> get(
    String endpoint, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return response;
  }
  Future<http.Response> patch(
  String endpoint, {
  Map<String, dynamic>? body,
  String? token,
}) async {
  final response = await http.patch(
    Uri.parse('$baseUrl$endpoint'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: body != null ? jsonEncode(body) : null,
  );

  return response;
}
}