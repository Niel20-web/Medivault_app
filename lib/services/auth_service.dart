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

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final accessToken = data['accessToken'];

      await _authStorage.saveAccessToken(accessToken);

      return data;
    }

    throw Exception(
      data['error']?['message'] ?? 'Login failed',
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