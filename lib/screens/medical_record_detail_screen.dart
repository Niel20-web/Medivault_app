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

  // ============================================================
  // DATA HELPERS
  // ============================================================

  Map<String, dynamic> get data {
    final rawData = record['data'];

    if (rawData is Map) {
      return {
        ...record,
        ...Map<String, dynamic>.from(rawData),
      };
    }

    return record;
  }

  bool get isDiagnosis => type == 'diagnosis';

  bool get isVital =>
      type == 'vital' ||
      type == 'vitals';

  bool get isPrescription =>
      type == 'prescription' ||
      type == 'prescriptions';

  bool get isDocument =>
      type == 'document';

  bool get isLabReport =>
      type == 'lab_report' ||
      type == 'labReport' ||
      type == 'lab';

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String _value(
    dynamic value, {
    String fallback = 'Not available',
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is String ||
        value is num ||
        value is bool) {
      final text = value.toString().trim();

      return text.isEmpty
          ? fallback
          : text;
    }

    if (value is Map) {
      final map =
          Map<String, dynamic>.from(value);

      final nestedValue =
          map['name'] ??
          map['displayName'] ??
          map['title'] ??
          map['label'] ??
          map['value'] ??
          map['text'] ??
          map['description'] ??
          map['code'];

      if (nestedValue != null) {
        return _value(
          nestedValue,
          fallback: fallback,
        );
      }
    }

    if (value is List) {
      if (value.isEmpty) {
        return fallback;
      }

      final result = value
          .map(
            (item) => _value(
              item,
              fallback: '',
            ),
          )
          .where(
            (item) => item.isNotEmpty,
          )
          .join(', ');

      return result.isEmpty
          ? fallback
          : result;
    }

    final text =
        value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }

  String _firstValue(
    List<dynamic> values, {
    String fallback = 'Not available',
  }) {
    for (final value in values) {
      final result = _value(
        value,
        fallback: '',
      );

      if (result.isNotEmpty) {
        return result;
      }
    }

    return fallback;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Not available';
    }

    try {
      final date =
          DateTime.parse(value.toString());

      return '${date.day} '
          '${_monthName(date.month)} '
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Not available';
    }

    try {
      final date =
          DateTime.parse(value.toString());

      final hour = date.hour > 12
          ? date.hour - 12
          : date.hour == 0
              ? 12
              : date.hour;

      final minute =
          date.minute.toString().padLeft(
                2,
                '0',
              );

      final period =
          date.hour >= 12
              ? 'PM'
              : 'AM';

      return '${date.day} '
          '${_monthName(date.month)} '
          '${date.year}, '
          '$hour:$minute $period';
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

    if (month < 1 ||
        month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // ============================================================
  // PRESCRIPTION STATUS
  // ============================================================

  String _getPrescriptionStatus() {
    // ----------------------------------------------------------
    // 1. Explicit backend status
    // ----------------------------------------------------------

    final explicitStatus =
        _firstValue(
      [
        data['status'],
        data['prescriptionStatus'],
        record['status'],
        record['prescriptionStatus'],
      ],
      fallback: '',
    );

    if (explicitStatus.isNotEmpty) {
      return _formatPrescriptionStatus(
        explicitStatus,
      );
    }

    // ----------------------------------------------------------
    // 2. isActive
    // ----------------------------------------------------------

    final dynamic isActive =
        data['isActive'] ??
        record['isActive'];

    if (isActive is bool) {
      return isActive
          ? 'Active'
          : 'Ended';
    }

    if (isActive is String) {
      final value =
          isActive.toLowerCase().trim();

      if (value == 'true' ||
          value == 'active' ||
          value == 'ongoing' ||
          value == 'current') {
        return 'Active';
      }

      if (value == 'false' ||
          value == 'ended' ||
          value == 'inactive' ||
          value == 'completed' ||
          value == 'cancelled' ||
          value == 'canceled' ||
          value == 'stopped' ||
          value == 'discontinued' ||
          value == 'expired') {
        return 'Ended';
      }
    }

    // ----------------------------------------------------------
    // 3. Explicit end / expiry date
    // ----------------------------------------------------------

    final dynamic endedAt =
        data['endedAt'] ??
        data['endDate'] ??
        data['expiresAt'] ??
        data['stopDate'];

    if (endedAt != null) {
      final parsedDate =
          DateTime.tryParse(
        endedAt.toString(),
      );

      if (parsedDate != null) {
        return parsedDate
                .isBefore(DateTime.now())
            ? 'Ended'
            : 'Active';
      }
    }

    // ----------------------------------------------------------
    // 4. Infer status from duration + prescribed date
    //
    // Example:
    // prescribedAt = 6 Oct 2026
    // duration = 8 days
    //
    // Current date = 7 Oct 2026
    // => Active
    // ----------------------------------------------------------

    final duration =
        _firstValue(
      [
        data['duration'],
        data['treatmentDuration'],
      ],
      fallback: '',
    );

    final prescribedDate =
        data['prescribedAt'] ??
        data['prescribedDate'] ??
        data['date'] ??
        data['startDate'] ??
        data['createdAt'] ??
        record['createdAt'];

    if (duration.isNotEmpty &&
        prescribedDate != null) {
      final startDate =
          DateTime.tryParse(
        prescribedDate.toString(),
      );

      if (startDate != null) {
        final durationDays =
            _extractDurationDays(
          duration,
        );

        if (durationDays != null) {
          final endDate =
              startDate.add(
            Duration(
              days: durationDays,
            ),
          );

          return DateTime.now()
                  .isBefore(endDate)
              ? 'Active'
              : 'Ended';
        }
      }
    }

    // ----------------------------------------------------------
    // 5. Nothing available
    // ----------------------------------------------------------

    return 'Not available';
  }

  String _formatPrescriptionStatus(
    String status,
  ) {
    final value =
        status.trim().toLowerCase();

    switch (value) {
      case 'active':
        return 'Active';

      case 'ongoing':
        return 'Active';

      case 'current':
        return 'Active';

      case 'in_progress':
      case 'in progress':
        return 'In Progress';

      case 'ended':
        return 'Ended';

      case 'inactive':
        return 'Inactive';

      case 'completed':
        return 'Completed';

      case 'cancelled':
      case 'canceled':
        return 'Cancelled';

      case 'stopped':
        return 'Stopped';

      case 'discontinued':
        return 'Discontinued';

      case 'expired':
        return 'Expired';

      default:
        return status;
    }
  }

  int? _extractDurationDays(
    String duration,
  ) {
    final text =
        duration.toLowerCase().trim();

    final match =
        RegExp(
      r'(\d+(?:\.\d+)?)\s*(day|days|week|weeks|month|months)',
    ).firstMatch(text);

    if (match == null) {
      return null;
    }

    final number =
        double.tryParse(
      match.group(1) ?? '',
    );

    if (number == null) {
      return null;
    }

    final unit =
        match.group(2) ?? '';

    if (unit.startsWith('day')) {
      return number.round();
    }

    if (unit.startsWith('week')) {
      return (number * 7).round();
    }

    if (unit.startsWith('month')) {
      return (number * 30).round();
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

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
    } else if (isLabReport) {
      title = 'Lab Report';
    } else {
      title = 'Medical Record';
    }

    return Scaffold(
      backgroundColor:
          Appcolors.background,
      appBar: AppBar(
        backgroundColor:
            Appcolors.background,
        elevation: 0,
        foregroundColor:
            Appcolors.primaryText,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: isDiagnosis
              ? _buildDiagnosisDetails()
              : isVital
                  ? _buildVitalsDetails()
                  : isPrescription
                      ? _buildPrescriptionDetails()
                      : isDocument
                          ? _buildDocumentDetails(
                              context,
                            )
                          : isLabReport
                              ? _buildLabReportDetails()
                              : _buildGenericDetails(),
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT
  // ============================================================

  Widget _buildDocumentDetails(
    BuildContext context,
  ) {
    final title =
        _firstValue(
      [
        data['title'],
        data['name'],
        data['fileName'],
        data['filename'],
        data['documentName'],
      ],
      fallback:
          'Medical Document',
    );

    final documentType =
        _firstValue(
      [
        data['type'],
        data['documentType'],
        data['mimeType'],
        data['contentType'],
        data['category'],
      ],
    );

    final description =
        _firstValue(
      [
        data['description'],
        data['notes'],
        data['details'],
      ],
    );

    final uploadedAt =
        _formatDate(
      data['uploadedAt'] ??
          data['createdAt'] ??
          data['date'],
    );

    final updatedAt =
        _formatDate(
      data['updatedAt'],
    );

    final fileName =
        _firstValue(
      [
        data['fileName'],
        data['filename'],
        data['originalName'],
      ],
    );

    final sourceHospital =
        _value(
      data['sourceHospital'],
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon:
              Icons.description_outlined,
          title: title,
          subtitle: documentType,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Document Information',
        ),

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

        _buildSectionTitle(
          'Description',
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            Text(
              description ==
                      'Not available'
                  ? 'No additional description is available.'
                  : description,
              style: const TextStyle(
                fontSize: 14,
                color:
                    Appcolors.secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child:
              ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentViewerScreen(
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
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Appcolors.primary,
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 15,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
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
    final diagnosis =
        _firstValue(
      [
        data['diagnosis'],
        data['diagnosisName'],
        data['name'],
        data['displayName'],
        data['title'],
        data['condition'],
        data['description'],
      ],
      fallback: 'Diagnosis',
    );

    final status =
        _value(
      data['status'],
    );

    final diagnosisDate =
        _formatDate(
      data['diagnosedAt'] ??
          data['date'] ??
          data['recordedAt'] ??
          data['createdAt'],
    );

    final description =
        _firstValue(
      [
        data['description'],
        data['details'],
        data['notes'],
      ],
    );

    final code =
        _firstValue(
      [
        data['code'],
        data['diagnosisCode'],
        data['icdCode'],
        data['icd10Code'],
      ],
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons
              .medical_information_outlined,
          title: diagnosis,
          subtitle: 'Diagnosis',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Diagnosis Information',
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Diagnosis',
              value: diagnosis,
            ),
            _buildInfoRow(
              label: 'Status',
              value: status,
            ),
            _buildInfoRow(
              label: 'Date',
              value: diagnosisDate,
            ),
            _buildInfoRow(
              label: 'Code',
              value: code,
            ),
            _buildInfoRow(
              label: 'Notes',
              value: description,
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
    final recordedAt =
        _formatDateTime(
      data['recordedAt'] ??
          data['date'] ??
          data['createdAt'],
    );

    final bloodPressure =
        _firstValue(
      [
        data['bloodPressure'],
        data['bp'],
        data['blood_pressure'],
      ],
    );

    final heartRate =
        _firstValue(
      [
        data['heartRate'],
        data['pulse'],
        data['heart_rate'],
      ],
    );

    final temperature =
        _firstValue(
      [
        data['temperature'],
        data['temp'],
      ],
    );

    final weight =
        _firstValue(
      [
        data['weight'],
        data['weightKg'],
      ],
    );

    final height =
        _firstValue(
      [
        data['height'],
        data['heightCm'],
      ],
    );

    final oxygenSaturation =
        _firstValue(
      [
        data['oxygenSaturation'],
        data['spo2'],
        data['oxygen'],
        data['o2Saturation'],
      ],
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon:
              Icons.favorite_border,
          title: 'Vital Signs',
          subtitle: recordedAt,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Vital Information',
        ),

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
              label: 'Temperature',
              value: temperature,
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
              label: 'Oxygen Saturation',
              value:
                  oxygenSaturation,
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
    final medicine =
        _firstValue(
      [
        data['medicationName'],
        data['medicineName'],
        data['name'],
        data['medicine'],
        data['drugName'],
      ],
      fallback: 'Prescription',
    );

    final dosage =
        _firstValue(
      [
        data['dosage'],
        data['dose'],
      ],
    );

    final frequency =
        _firstValue(
      [
        data['frequency'],
        data['doseFrequency'],
        data['schedule'],
        data['frequencyText'],
      ],
    );

    final duration =
        _firstValue(
      [
        data['duration'],
        data['treatmentDuration'],
      ],
    );

    final instructions =
        _firstValue(
      [
        data['instructions'],
        data['directions'],
        data['notes'],
      ],
    );

    // FIXED:
    // This no longer only checks data['status'].
    final status =
        _getPrescriptionStatus();

    final prescribedAt =
        _formatDate(
      data['prescribedAt'] ??
          data['prescribedDate'] ??
          data['date'] ??
          data['startDate'] ??
          data['createdAt'] ??
          record['createdAt'],
    );

    final prescribedBy =
        _firstValue(
      [
        data['prescribedBy'],
        data['doctorName'],
        data['orderedBy'],
        data['authorName'],
        record['authorName'],
      ],
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon:
              Icons.medication_outlined,
          title: medicine,
          subtitle: 'Prescription',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Prescription Information',
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Medicine',
              value: medicine,
            ),
            _buildInfoRow(
              label: 'Dosage',
              value: dosage,
            ),
            _buildInfoRow(
              label: 'Frequency',
              value: frequency,
            ),
            _buildInfoRow(
              label: 'Duration',
              value: duration,
            ),
            _buildInfoRow(
              label: 'Instructions',
              value: instructions,
            ),
            _buildInfoRow(
              label: 'Status',
              value: status,
            ),
            _buildInfoRow(
              label: 'Prescribed',
              value: prescribedAt,
            ),
            _buildInfoRow(
              label: 'Prescribed By',
              value: prescribedBy,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // LAB REPORT
  // ============================================================

  Widget _buildLabReportDetails() {
    final testName =
        _firstValue(
      [
        data['testName'],
        data['name'],
        data['test'],
        data['title'],
      ],
      fallback:
          'Laboratory Test',
    );

    final testCode =
        _firstValue(
      [
        data['testCode'],
        data['code'],
      ],
    );

    final result =
        _firstValue(
      [
        data['results'],
        data['result'],
        data['value'],
        data['resultValue'],
      ],
    );

    final status =
        _firstValue(
      [
        data['status'],
        data['resultStatus'],
        data['interpretationStatus'],
      ],
    );

    final normalRange =
        _firstValue(
      [
        data['normalRange'],
        data['referenceRange'],
        data['reference'],
        data['normalValues'],
      ],
    );

    final unit =
        _firstValue(
      [
        data['unit'],
        data['units'],
      ],
    );

    final labName =
        _firstValue(
      [
        data['labName'],
        data['laboratory'],
        data['lab'],
      ],
    );

    final reportDate =
        _formatDate(
      data['reportDate'] ??
          data['resultedAt'] ??
          data['date'] ??
          data['createdAt'],
    );

    final collectedAt =
        _formatDateTime(
      data['collectedAt'],
    );

    final resultedAt =
        _formatDateTime(
      data['resultedAt'],
    );

    final orderedBy =
        _firstValue(
      [
        data['orderedBy'],
        data['doctorName'],
        data['prescribedBy'],
        data['authorName'],
      ],
    );

    final interpretation =
        _firstValue(
      [
        data['interpretation'],
        data['resultInterpretation'],
      ],
    );

    final notes =
        _firstValue(
      [
        data['notes'],
        data['note'],
      ],
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon:
              Icons.science_outlined,
          title: testName,
          subtitle: 'Laboratory Test',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Test Information',
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Test Name',
              value: testName,
            ),
            _buildInfoRow(
              label: 'Test Code',
              value: testCode,
            ),
            _buildInfoRow(
              label: 'Lab Name',
              value: labName,
            ),
            _buildInfoRow(
              label: 'Report Date',
              value: reportDate,
            ),
            _buildInfoRow(
              label: 'Collected',
              value: collectedAt,
            ),
            _buildInfoRow(
              label: 'Resulted',
              value: resultedAt,
            ),
            _buildInfoRow(
              label: 'Ordered By',
              value: orderedBy,
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Test Result',
        ),

        const SizedBox(height: 12),

        _buildResultCard(
          result: result,
          unit: unit,
          status: status,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Reference Information',
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Normal Range',
              value: normalRange,
            ),
            _buildInfoRow(
              label: 'Unit',
              value: unit,
            ),
            _buildInfoRow(
              label: 'Interpretation',
              value: interpretation,
            ),
          ],
        ),

        if (notes !=
            'Not available') ...[
          const SizedBox(height: 24),

          _buildSectionTitle(
            'Notes',
          ),

          const SizedBox(height: 12),

          _buildInfoCard(
            children: [
              Text(
                notes,
                style:
                    const TextStyle(
                  fontSize: 14,
                  color: Appcolors
                      .secondaryText,
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
  // LAB RESULT CARD
  // ============================================================

  Widget _buildResultCard({
    required String result,
    required String unit,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Appcolors.primary
            .withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Appcolors.primary
              .withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Result',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  Appcolors.secondaryText,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  result,
                  style:
                      const TextStyle(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Appcolors.primaryText,
                  ),
                ),
              ),
              if (unit !=
                  'Not available')
                Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    bottom: 4,
                  ),
                  child: Text(
                    unit,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color: Appcolors
                          .secondaryText,
                    ),
                  ),
                ),
            ],
          ),

          if (status !=
              'Not available') ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration:
                  BoxDecoration(
                color: Appcolors.surface,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                status,
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Appcolors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // GENERIC
  // ============================================================

  Widget _buildGenericDetails() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon:
              Icons.folder_outlined,
          title: 'Medical Record',
          subtitle: '',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Information',
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          children:
              data.entries.map(
            (entry) {
              return _buildInfoRow(
                label: _formatLabel(
                  entry.key,
                ),
                value: _value(
                  entry.value,
                ),
              );
            },
          ).toList(),
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
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Appcolors.primary
            .withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color:
                  Appcolors.primary,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                    color: Appcolors
                        .primaryText,
                  ),
                ),

                if (subtitle
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      color: Appcolors
                          .secondaryText,
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight:
            FontWeight.w800,
        color:
            Appcolors.primaryText,
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
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
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 14,
                color: Appcolors
                    .secondaryText,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontSize: 14,
                color: Appcolors
                    .primaryText,
                fontWeight:
                    FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABEL FORMATTER
  // ============================================================

  String _formatLabel(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    final spaced = value
        .replaceAllMapped(
          RegExp(
            r'([a-z])([A-Z])',
          ),
          (match) =>
              '${match.group(1)} '
              '${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    return spaced
        .split(' ')
        .where(
          (word) => word.isNotEmpty,
        )
        .map(
          (word) =>
              '${word[0].toUpperCase()}'
              '${word.substring(1)}',
        )
        .join(' ');
  }
}