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
      final String? accessToken =
          data['data']?['accessToken'] as String?;

      print(
        'ACCESS TOKEN RECEIVED: ${accessToken != null}',
      );

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
    String role = 'PATIENT',
    bool createPatientIdentity = true,
    Map<String, dynamic>? identity,
  }) async {
    final Map<String, dynamic> requestBody = {
      'email': email.trim(),
      'username': username.trim(),
      'password': password,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'role': role,
      'createPatientIdentity': createPatientIdentity,
    };

    if (phone != null && phone.trim().isNotEmpty) {
      requestBody['phone'] = phone.trim();
    }

    if (identity != null) {
      requestBody['identity'] = identity;
    }

    print('REGISTER REQUEST: ${jsonEncode(requestBody)}');

    final response = await _apiService.post(
      '/auth/register',
      body: requestBody,
    );

    print('REGISTER STATUS: ${response.statusCode}');
    print('REGISTER RESPONSE: ${response.body}');

    dynamic decodedData;

    try {
      decodedData = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Registration failed. The server returned an invalid response.',
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      if (decodedData is Map) {
        return Map<String, dynamic>.from(decodedData);
      }

      throw Exception(
        'Registration succeeded but the server returned an unexpected response.',
      );
    }

    String errorMessage = 'Registration failed.';

    if (decodedData is Map) {
      final dynamic error = decodedData['error'];

      if (error is Map) {
        final dynamic message = error['message'];

        if (message != null &&
            message.toString().trim().isNotEmpty) {
          errorMessage = message.toString();
        }
      }

      if (errorMessage == 'Registration failed.') {
        final dynamic message = decodedData['message'];

        if (message != null &&
            message.toString().trim().isNotEmpty) {
          errorMessage = message.toString();
        }
      }
    }

    throw Exception(errorMessage);
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
    } catch (e) {
      // The server call is best effort
      // (offline, expired token, etc.).
      // The user must still be logged out locally.
      print(
        'LOGOUT REQUEST FAILED (ignored): $e',
      );
    } finally {
      await _authStorage.deleteAccessToken();
    }
  }
}