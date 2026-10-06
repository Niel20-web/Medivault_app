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

    print(
      'MEDICAL SUMMARY STATUS: ${response.statusCode}',
    );

    print(
      'MEDICAL SUMMARY RESPONSE: ${response.body}',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['error']?['message'] ??
          'Failed to load medical records',
    );
  }

  // ---------------------------------------------------------------------------
  // DOCUMENT METADATA
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getDocumentMetadata({
    required String patientId,
    required String documentId,
  }) async {
    final token = await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception('No access token found.');
    }

    final response = await _apiService.get(
      '/patients/$patientId/documents/$documentId',
      token: token,
    );

    print(
      'DOCUMENT METADATA STATUS: ${response.statusCode}',
    );

    print(
      'DOCUMENT METADATA RESPONSE: ${response.body}',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error']?['message'] ??
            'Failed to get document metadata',
      );
    }

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Invalid document metadata response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ---------------------------------------------------------------------------
  // DOCUMENT DOWNLOAD URL
  // ---------------------------------------------------------------------------

  Future<String> getDocumentUrl({
    required String patientId,
    required String documentId,
  }) async {
    final token = await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception('No access token found.');
    }

    final response = await _apiService.get(
      '/patients/$patientId/documents/$documentId/download-url?mode=inline',
      token: token,
    );

    print(
      'DOCUMENT URL STATUS: ${response.statusCode}',
    );

    print(
      'DOCUMENT URL RESPONSE: ${response.body}',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error']?['message'] ??
            'Failed to get document URL',
      );
    }

    final responseData = data['data'];

    if (responseData is! Map ||
        responseData['url'] == null) {
      throw Exception(
        'Document URL was not returned by the server.',
      );
    }

    final String url =
        responseData['url'].toString();

    print('DOCUMENT URL: $url');

    if (url.startsWith('http://') ||
        url.startsWith('https://')) {
      return url;
    }

    final baseUri =
        Uri.parse(ApiService.baseUrl);

    return baseUri.resolve(url).toString();
  }
}