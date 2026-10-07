import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_manager.dart';

class ApiService {
  static const String baseUrl =
      'https://medivault-xi-two.vercel.app/api/v1';

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// If an authenticated request comes back 401, the saved session is no
  /// longer valid: clear it and send the user back to the login flow.
  /// Logout itself is excluded so a failed logout call doesn't show an
  /// "expired" message.
  http.Response _checkSession(
    http.Response response,
    String endpoint,
    String? token,
  ) {
    if (token != null &&
        response.statusCode == 401 &&
        endpoint != '/auth/logout') {
      SessionManager.instance.handleSessionExpired();
    }

    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );

    return _checkSession(response, endpoint, token);
  }

  Future<http.Response> get(
    String endpoint, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(token),
    );

    return _checkSession(response, endpoint, token);
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );

    return _checkSession(response, endpoint, token);
  }
}
