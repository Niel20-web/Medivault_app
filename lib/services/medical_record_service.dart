import 'dart:convert';

import 'api_service.dart';
import '../utils/auth_storage.dart';

class MedicalRecordService {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  Future<Map<String, dynamic>> getMedicalSummary(
    String patientId,
  ) async {
    final token = await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception('No access token found.');
    }

    final response = await _apiService.get(
      '/patients/$patientId/medical-summary',
      token: token,
    );

    print('MEDICAL SUMMARY STATUS: ${response.statusCode}');
    print('MEDICAL SUMMARY RESPONSE: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ?? 'Failed to load medical records',
    );
  }
}