import 'dart:convert';

import 'api_service.dart';
import '../utils/auth_storage.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN RESPONSE: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final String? accessToken = data['data']?['accessToken'] as String?;

      print('ACCESS TOKEN RECEIVED: ${accessToken != null}');

      if (accessToken == null) {
        throw Exception(
          'Login succeeded but the backend did not return accessToken.',
        );
      }

      await _authStorage.saveAccessToken(accessToken);

      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ?? 'Login failed',
    );
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    Map<String, dynamic>? identity,
  }) async {
    final response = await _apiService.post(
      '/auth/register',
      body: {
        'email': email,
        'username': username,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': 'PATIENT',
        'createPatientIdentity': true,
        if (identity != null) 'identity': identity,
      },
    );

    print('REGISTER STATUS: ${response.statusCode}');
    print('REGISTER RESPONSE: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ?? 'Registration failed',
    );
  }

  Future<void> logout() async {
    final token = await _authStorage.getAccessToken();

    try {
      if (token != null) {
        await _apiService.post(
          '/auth/logout',
          token: token,
        );
      }
    } finally {
      await _authStorage.deleteAccessToken();
    }
  }
}