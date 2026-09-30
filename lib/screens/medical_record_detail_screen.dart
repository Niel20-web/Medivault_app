import 'package:flutter/material.dart';

import '../utils/appcolors.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final String type;
  final Map<String, dynamic> record;

  const MedicalRecordDetailScreen({
    super.key,
    required this.type,
    required this.record,
  });

  Map<String, dynamic> get data {
    final recordData = record['data'];

    if (recordData is Map) {
      return Map<String, dynamic>.from(recordData);
    }

    return {};
  }

  bool get isDiagnosis => type == 'diagnosis';

  bool get isVital => type == 'vital';

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not available';
    }

    try {
      final date = DateTime.parse(value.toString());

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _value(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not available';
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    String title;

    if (isDiagnosis) {
      title = 'Medical Record';
    } else if (isVital) {
      title = 'Vital Record';
    } else {
      title = 'Medical Record';
    }

    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Appcolors.primaryText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Appcolors.primaryText,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: isDiagnosis
            ? _buildDiagnosisDetails()
            : isVital
                ? _buildVitalsDetails()
                : _buildGenericDetails(),
      ),
    );
  }

  // ============================================================
  // DIAGNOSIS
  // ============================================================

  Widget _buildDiagnosisDetails() {
    final diagnosisName = _value(data['diagnosisName']);
    final status = _value(data['status']);
    final severity = _value(data['severity']);
    final diagnosisCode = _value(data['diagnosisCode']);
    final diagnosisType = _value(data['diagnosisType']);
    final notes = _value(data['notes']);
    final diagnosedAt = _formatDate(data['diagnosedAt']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.medical_services_outlined,
          title: diagnosisName,
          subtitle: 'Diagnosis',
          status: status,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Diagnosis'),
        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Condition',
              value: diagnosisName,
            ),
            _buildInfoRow(
              label: 'Status',
              value: status,
            ),
            _buildInfoRow(
              label: 'Severity',
              value: severity,
            ),
            _buildInfoRow(
              label: 'Diagnosis type',
              value: diagnosisType,
            ),
            _buildInfoRow(
              label: 'Diagnosis code',
              value: diagnosisCode,
            ),
            _buildInfoRow(
              label: 'Diagnosed',
              value: diagnosedAt,
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Medical Notes'),
        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            Text(
              notes == 'Not available'
                  ? 'No additional medical notes available.'
                  : notes,
              style: const TextStyle(
                fontSize: 14,
                color: Appcolors.secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // VITALS
  // ============================================================

  Widget _buildVitalsDetails() {
    final systolic = data['bloodPressureSystolic'];
    final diastolic = data['bloodPressureDiastolic'];

    String bloodPressure = 'Not available';

    if (systolic != null && diastolic != null) {
      bloodPressure = '$systolic/$diastolic mmHg';
    }

    final heartRate = data['heartRate'] != null
        ? '${data['heartRate']} bpm'
        : 'Not available';

    final oxygenSaturation = data['oxygenSaturation'] != null
        ? '${data['oxygenSaturation']}%'
        : 'Not available';

    final temperature = data['temperature'] != null
        ? '${data['temperature']} °C'
        : 'Not available';

    final respiratoryRate = data['respiratoryRate'] != null
        ? '${data['respiratoryRate']} breaths/min'
        : 'Not available';

    final weight = data['weight'] != null
        ? '${data['weight']} kg'
        : 'Not available';

    final height = data['height'] != null
        ? '${data['height']} cm'
        : 'Not available';

    final bmi = _value(data['bmi']);

    final glucose = data['glucose'] != null
        ? '${data['glucose']}'
        : 'Not available';

    final recordedAt = _formatDate(data['recordedAt']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.favorite_outline,
          title: 'Vital Signs',
          subtitle: 'Recorded measurements',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Measurements'),
        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Blood Pressure',
              value: bloodPressure,
            ),
            _buildInfoRow(
              label: 'Heart Rate',
              value: heartRate,
            ),
            _buildInfoRow(
              label: 'SpO₂',
              value: oxygenSaturation,
            ),
            _buildInfoRow(
              label: 'Temperature',
              value: temperature,
            ),
            _buildInfoRow(
              label: 'Respiratory Rate',
              value: respiratoryRate,
            ),
            _buildInfoRow(
              label: 'Weight',
              value: weight,
            ),
            _buildInfoRow(
              label: 'Height',
              value: height,
            ),
            _buildInfoRow(
              label: 'BMI',
              value: bmi,
            ),
            _buildInfoRow(
              label: 'Glucose',
              value: glucose,
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Recorded'),
        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Date',
              value: recordedAt,
            ),
          ],
        ),

        if (data['notes'] != null) ...[
          const SizedBox(height: 24),

          _buildSectionTitle('Notes'),
          const SizedBox(height: 12),

          _buildInfoCard(
            children: [
              Text(
                data['notes'].toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Appcolors.secondaryText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================================
  // GENERIC RECORD
  // ============================================================

  Widget _buildGenericDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.description_outlined,
          title: 'Medical Record',
          subtitle: type,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Record Details'),
        const SizedBox(height: 12),

        _buildInfoCard(
          children: data.entries.map((entry) {
            return _buildInfoRow(
              label: _formatLabel(entry.key),
              value: _value(entry.value),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    String? status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Appcolors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Appcolors.primary,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Appcolors.primaryText,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Appcolors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          if (status != null &&
              status != 'Not available' &&
              status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Appcolors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Appcolors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Appcolors.primaryText,
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Appcolors.secondaryText,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Appcolors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT FIELD NAME
  // ============================================================

  String _formatLabel(String value) {
    final result = value
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .replaceAll('_', ' ')
        .trim();

    if (result.isEmpty) {
      return value;
    }

    return result[0].toUpperCase() + result.substring(1);
  }
}