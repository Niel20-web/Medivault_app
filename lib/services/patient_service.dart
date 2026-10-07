import 'dart:convert';

import 'api_service.dart';
import '../utils/auth_storage.dart';

class PatientService {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  // ─────────────────────────────────────────────
  // Get patient profile
  // ─────────────────────────────────────────────

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
      data['error']?['message'] ??
          'Failed to load patient profile',
    );
  }

  // ─────────────────────────────────────────────
  // Get complete medical history
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getMedicalHistory(
    String patientId,
  ) async {
    final token = await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception('No access token found.');
    }

    final response = await _apiService.get(
      '/patients/$patientId/history',
      token: token,
    );

    print(
      'MEDICAL HISTORY STATUS: ${response.statusCode}',
    );
    print(
      'MEDICAL HISTORY RESPONSE: ${response.body}',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ??
          'Failed to load medical history',
    );
  }

  // ─────────────────────────────────────────────
  // Update patient profile
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> updateMyPatientProfile({
    String? firstName,
    String? lastName,
    String? middleName,
    String? phone,
    String? email,
    String? city,
    String? state,
    String? pincode,
  }) async {
    final token = await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception('No access token found.');
    }

    final body = <String, dynamic>{
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (middleName != null) 'middleName': middleName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
    };

    final response = await _apiService.patch(
      '/patients/me',
      body: body,
      token: token,
    );

    print(
      'UPDATE PROFILE STATUS: ${response.statusCode}',
    );
    print(
      'UPDATE PROFILE RESPONSE: ${response.body}',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ??
          'Failed to update profile',
    );
  }

  // ─────────────────────────────────────────────
  // Update notification preferences
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> updateNotificationPreferences({
    bool? notificationsEnabled,
    bool? emailNotifications,
  }) async {
    final token = await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception('No access token found.');
    }

    final preferences = <String, dynamic>{
      if (notificationsEnabled != null)
        'notificationsEnabled': notificationsEnabled,
      if (emailNotifications != null)
        'emailNotifications': emailNotifications,
    };

    final response = await _apiService.patch(
      '/patients/me',
      body: {
        'preferences': preferences,
      },
      token: token,
    );

    print(
      'UPDATE NOTIFICATIONS STATUS: ${response.statusCode}',
    );
    print(
      'UPDATE NOTIFICATIONS RESPONSE: ${response.body}',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ??
          'Failed to update notification preferences',
    );
  }
  Future<Map<String, dynamic>> generateMedicalQr(
  String patientId,
) async {
  final token = await _authStorage.getAccessToken();

  if (token == null) {
    throw Exception('No access token found.');
  }

  final response = await _apiService.post(
    '/medical-profile/patients/$patientId/qr',
    body: {
    'baseUrl': 'https://medivault-xi-two.vercel.app',
    },
    token: token,
  );

  print('MEDICAL QR STATUS: ${response.statusCode}');
  print('MEDICAL QR RESPONSE: ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception(
    data['error']?['message'] ??
        'Failed to generate Medical ID QR',
  );
}
Future<Map<String, dynamic>> getPatientDocuments(
  String patientId,
) async {
  final token = await _authStorage.getAccessToken();

  if (token == null) {
    throw Exception('No access token found.');
  }

  final response = await _apiService.get(
    '/patients/$patientId/documents',
    token: token,
  );

  print('PATIENT DOCUMENTS STATUS: ${response.statusCode}');
  print('PATIENT DOCUMENTS RESPONSE: ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception(
    data['error']?['message'] ??
        'Failed to load patient documents',
  );
}
Future<Map<String, dynamic>> getLabReports(
  String patientId,
) async {
  final token = await _authStorage.getAccessToken();

  if (token == null) {
    throw Exception('No access token found.');
  }

  final response = await _apiService.get(
    '/patients/$patientId/lab-reports',
    token: token,
  );

  print('LAB REPORTS STATUS: ${response.statusCode}');
  print('LAB REPORTS RESPONSE: ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception(
    data['error']?['message'] ??
        'Failed to load lab reports',
  );
}
}