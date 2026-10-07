import 'package:flutter/material.dart';

import '../services/patient_service.dart';

class LabReportsScreen extends StatefulWidget {
  const LabReportsScreen({super.key});

  @override
  State<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends State<LabReportsScreen> {
  final PatientService _patientService = PatientService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadLabReports();
  }

Future<void> _loadLabReports() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await _patientService.getMyPatientProfile();

    // Your API may return:
    //
    // {
    //   "data": {
    //     "_id": "..."
    //   }
    // }
    //
    // or directly:
    //
    // {
    //   "_id": "..."
    // }
    //
    // Support both formats.

    Map<String, dynamic> patient;

    final patientData = response['data'];

    if (patientData is Map) {
      patient = Map<String, dynamic>.from(patientData);
    } else {
      patient = Map<String, dynamic>.from(response);
    }

    final patientId = patient['_id']?.toString();

    print('LAB REPORTS PATIENT: $patient');
    print('LAB REPORTS PATIENT ID: $patientId');

    if (patientId == null || patientId.isEmpty) {
      throw Exception(
        'Patient ID not found in patient profile.',
      );
    }

    final labResponse =
        await _patientService.getLabReports(patientId);

    print('LAB REPORT API RESPONSE: $labResponse');

    // Support multiple possible response shapes.
    //
    // Example 1:
    // { "data": [ ... ] }
    //
    // Example 2:
    // { "data": { "data": [ ... ] } }
    //
    // Example 3:
    // { "reports": [ ... ] }

    dynamic rawData;

    if (labResponse['data'] is List) {
      rawData = labResponse['data'];
    } else if (labResponse['data'] is Map) {
      final nested = labResponse['data'];

      if (nested['data'] is List) {
        rawData = nested['data'];
      } else if (nested['reports'] is List) {
        rawData = nested['reports'];
      }
    } else if (labResponse['reports'] is List) {
      rawData = labResponse['reports'];
    }

    final List<dynamic> rawReports =
        rawData is List ? rawData : [];

    final reports = rawReports
        .whereType<Map>()
        .map(
          (report) => Map<String, dynamic>.from(report),
        )
        .toList();

    if (!mounted) return;

    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  } catch (e) {
    print('LAB REPORTS ERROR: $e');

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst(
            'Exception: ',
            '',
          );
    });
  }
}

  Map<String, dynamic> _reportData(
    Map<String, dynamic> report,
  ) {
    final data = report['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return report;
  }

  String _value(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(text).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return text;
    }
  }

  String _statusText(Map<String, dynamic> data) {
    final status = _value(data, 'status');

    if (status.isEmpty) {
      return 'Reported';
    }

    return status;
  }

  Color _statusColor(Map<String, dynamic> data) {
    final status = _statusText(data).toLowerCase();

    if (status.contains('normal') ||
        status.contains('completed') ||
        status.contains('final')) {
      return Colors.green;
    }

    if (status.contains('high') ||
        status.contains('critical') ||
        status.contains('abnormal')) {
      return Colors.red;
    }

    if (status.contains('pending')) {
      return Colors.orange;
    }

    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Lab Reports',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadLabReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_reports.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadLabReports,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          return _buildReportCard(_reports[index]);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load lab reports',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadLabReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadLabReports,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.18,
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_outlined,
              size: 44,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Lab Reports Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your laboratory reports will appear here once they are added to your medical record.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    Map<String, dynamic> report,
  ) {
    final data = _reportData(report);

    final testName = _value(data, 'testName');
    final testCode = _value(data, 'testCode');
    final labName = _value(data, 'labName');
    final reportDate = _formatDate(data['reportDate']);
    final interpretation = _value(data, 'interpretation');
    final unit = _value(data, 'unit');
    final normalRange = _value(data, 'normalRange');
    final status = _statusText(data);

    final displayName = testName.isEmpty
        ? 'Laboratory Test'
        : testName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showReportDetails(report);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.science_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (testCode.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              testCode,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      status,
                      _statusColor(data),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        Icons.calendar_today_outlined,
                        'Report Date',
                        reportDate.isEmpty
                            ? 'Not provided'
                            : reportDate,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      Expanded(
                        child: _infoItem(
                          Icons.straighten_outlined,
                          'Unit',
                          unit,
                        ),
                      ),
                  ],
                ),
                if (labName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _infoItem(
                    Icons.local_hospital_outlined,
                    'Lab',
                    labName,
                  ),
                ],
                if (normalRange.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _infoItem(
                    Icons.compare_arrows_outlined,
                    'Normal Range',
                    normalRange,
                  ),
                ],
                if (interpretation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _infoItem(
                    Icons.analytics_outlined,
                    'Interpretation',
                    interpretation,
                  ),
                ],
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String status,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.black45,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportDetails(
    Map<String, dynamic> report,
  ) {
    final data = _reportData(report);

    final testName = _value(data, 'testName');
    final testCode = _value(data, 'testCode');
    final normalRange = _value(data, 'normalRange');
    final unit = _value(data, 'unit');
    final labName = _value(data, 'labName');
    final reportDate = _formatDate(data['reportDate']);
    final interpretation = _value(data, 'interpretation');
    final notes = _value(data, 'notes');
    final results = _value(data, 'results');
    final status = _statusText(data);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          testName.isEmpty
                              ? 'Lab Report'
                              : testName,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildStatusChip(
                        status,
                        _statusColor(data),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailRow(
                    'Test Name',
                    testName,
                  ),
                  _detailRow(
                    'Test Code',
                    testCode,
                  ),
                  _detailRow(
                    'Normal Range',
                    normalRange,
                  ),
                  _detailRow(
                    'Unit',
                    unit,
                  ),
                  _detailRow(
                    'Lab Name',
                    labName,
                  ),
                  _detailRow(
                    'Report Date',
                    reportDate,
                  ),
                  _detailRow(
                    'Results',
                    results,
                  ),
                  _detailRow(
                    'Interpretation',
                    interpretation,
                  ),
                  _detailRow(
                    'Notes',
                    notes,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}