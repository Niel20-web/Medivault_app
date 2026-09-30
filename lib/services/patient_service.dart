import 'dart:convert';

import 'api_service.dart';
import '../utils/auth_storage.dart';

class PatientService {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  Future<Map<String, dynamic>> getMyPatientProfile() async {
    final token = await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception('No access token found.');
    }

    final response = await _apiService.get(
      '/patients/me',
      token: token,
    );

    print('PATIENT STATUS: ${response.statusCode}');
    print('PATIENT RESPONSE: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ?? 'Failed to load patient profile',
    );
  }
}