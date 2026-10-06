import 'package:flutter/material.dart';

import 'document_viewer_screen.dart';
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
    final rawData = record['data'];

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    return record;
  }

  bool get isDiagnosis => type == 'diagnosis';
  bool get isVital => type == 'vital';
  bool get isPrescription => type == 'prescription';
  bool get isDocument => type == 'document';

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not available';
    }

    try {
      final date = DateTime.parse(value.toString());

      return '${date.day} '
          '${_monthName(date.month)} '
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
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
    } else if (isPrescription) {
      title = 'Prescription';
    } else if (isDocument) {
      title = 'Medical Document';
    } else {
      title = 'Medical Record';
    }

    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        foregroundColor: Appcolors.primaryText,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: isDiagnosis
              ? _buildDiagnosisDetails()
              : isVital
                  ? _buildVitalsDetails()
                  : isPrescription
                      ? _buildPrescriptionDetails()
                      : isDocument
                          ? _buildDocumentDetails(context)
                          : _buildGenericDetails(),
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT
  // ============================================================

  Widget _buildDocumentDetails(BuildContext context) {
    final title = _value(
      data['title'] ??
          data['name'] ??
          data['fileName'] ??
          data['filename'] ??
          data['documentName'] ??
          'Medical Document',
    );

    final documentType = _value(
      data['type'] ??
          data['documentType'] ??
          data['mimeType'] ??
          data['contentType'] ??
          data['category'],
    );

    final description = _value(
      data['description'] ??
          data['notes'] ??
          data['details'],
    );

    final uploadedAt = _formatDate(
      data['uploadedAt'] ??
          data['createdAt'] ??
          data['date'],
    );

    final updatedAt = _formatDate(
      data['updatedAt'],
    );

    final fileName = _value(
      data['fileName'] ??
          data['filename'] ??
          data['originalName'],
    );

    final sourceHospital = _value(
      data['sourceHospital'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.description_outlined,
          title: title,
          subtitle: documentType,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Document Information'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Document',
              value: title,
            ),
            _buildInfoRow(
              label: 'Category',
              value: documentType,
            ),
            _buildInfoRow(
              label: 'File name',
              value: fileName,
            ),
            _buildInfoRow(
              label: 'Hospital',
              value: sourceHospital,
            ),
            _buildInfoRow(
              label: 'Uploaded',
              value: uploadedAt,
            ),
            _buildInfoRow(
              label: 'Updated',
              value: updatedAt,
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Description'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            Text(
              description == 'Not available'
                  ? 'No additional description is available.'
                  : description,
              style: const TextStyle(
                fontSize: 14,
                color: Appcolors.secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    document: record,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.visibility_outlined,
            ),
            label: const Text(
              'View Document',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DIAGNOSIS
  // ============================================================

  Widget _buildDiagnosisDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.medical_information_outlined,
          title: _value(
            data['name'] ??
                data['diagnosis'] ??
                data['description'],
          ),
          subtitle: 'Diagnosis',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Diagnosis Information'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Diagnosis',
              value: _value(
                data['name'] ??
                    data['diagnosis'],
              ),
            ),
            _buildInfoRow(
              label: 'Status',
              value: _value(
                data['status'],
              ),
            ),
            _buildInfoRow(
              label: 'Date',
              value: _formatDate(
                data['diagnosedAt'] ??
                    data['date'] ??
                    data['createdAt'],
              ),
            ),
            _buildInfoRow(
              label: 'Notes',
              value: _value(
                data['notes'] ??
                    data['description'],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.favorite_border,
          title: 'Vital Signs',
          subtitle: _formatDate(
            data['recordedAt'] ??
                data['date'] ??
                data['createdAt'],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Vital Information'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Blood Pressure',
              value: _value(
                data['bloodPressure'],
              ),
            ),
            _buildInfoRow(
              label: 'Heart Rate',
              value: _value(
                data['heartRate'],
              ),
            ),
            _buildInfoRow(
              label: 'Temperature',
              value: _value(
                data['temperature'],
              ),
            ),
            _buildInfoRow(
              label: 'Weight',
              value: _value(
                data['weight'],
              ),
            ),
            _buildInfoRow(
              label: 'Height',
              value: _value(
                data['height'],
              ),
            ),
            _buildInfoRow(
              label: 'Oxygen Saturation',
              value: _value(
                data['oxygenSaturation'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PRESCRIPTION
  // ============================================================

  Widget _buildPrescriptionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.medication_outlined,
          title: _value(
            data['medicationName'] ??
                data['name'] ??
                data['medicine'],
          ),
          subtitle: 'Prescription',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Prescription Information'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Medicine',
              value: _value(
                data['medicationName'] ??
                    data['name'] ??
                    data['medicine'],
              ),
            ),
            _buildInfoRow(
              label: 'Dosage',
              value: _value(
                data['dosage'],
              ),
            ),
            _buildInfoRow(
              label: 'Frequency',
              value: _value(
                data['frequency'],
              ),
            ),
            _buildInfoRow(
              label: 'Duration',
              value: _value(
                data['duration'],
              ),
            ),
            _buildInfoRow(
              label: 'Instructions',
              value: _value(
                data['instructions'] ??
                    data['notes'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // GENERIC
  // ============================================================

  Widget _buildGenericDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.folder_outlined,
          title: 'Medical Record',
          subtitle: '',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Information'),

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
  // SHARED UI
  // ============================================================

  Widget _buildHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Appcolors.primary.withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Appcolors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Appcolors.primaryText,
                  ),
                ),

                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Appcolors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Appcolors.primaryText,
      ),
    );
  }

  Widget _buildInfoCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
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

  String _formatLabel(String value) {
    final formatted = value
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) =>
              '${match.group(1)} ${match.group(2)}',
        );

    return formatted
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}