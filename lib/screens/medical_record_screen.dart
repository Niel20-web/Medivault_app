import 'package:flutter/material.dart';

import '../utils/appcolors.dart';
import '../services/patient_service.dart';
import '../services/medical_record_service.dart';

import 'medical_record_detail_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState
    extends State<MedicalRecordsScreen> {
  final PatientService _patientService = PatientService();

  final MedicalRecordService _medicalRecordService =
      MedicalRecordService();

  String selectedFilter = 'All';
  String searchQuery = '';

  Map<String, dynamic>? _medicalSummary;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicalRecords();
  }

  Future<void> _loadMedicalRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get the logged-in patient's profile first.
      final patientResponse =
          await _patientService.getMyPatientProfile();

      final patientData = patientResponse['data'];

      if (patientData == null) {
        throw Exception(
          'Patient data was not returned by the server.',
        );
      }

      final patientUuid = patientData['_id'];

      if (patientUuid == null) {
        throw Exception(
          'Patient UUID was not returned by the server.',
        );
      }

      // Get the patient's medical summary.
      final summaryResponse =
          await _medicalRecordService.getMedicalSummary(
        patientUuid,
      );

      final summaryData = summaryResponse['data'];

      if (summaryData == null) {
        throw Exception(
          'Medical record data was not returned by the server.',
        );
      }

      if (!mounted) return;

      setState(() {
        _medicalSummary =
            Map<String, dynamic>.from(summaryData);

        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      print('MEDICAL RECORD SCREEN ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _buildMedicalRecords(),
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Appcolors.primary,
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Appcolors.error,
            ),

            const SizedBox(height: 14),

            const Text(
              'Unable to load medical records',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Appcolors.primaryText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Appcolors.secondaryText,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _loadMedicalRecords,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.primary,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEDICAL RECORDS
  // ============================================================

  Widget _buildMedicalRecords() {
    final totals = Map<String, dynamic>.from(
      _medicalSummary?['totals'] ?? {},
    );

    final diagnoses = List<dynamic>.from(
      _medicalSummary?['activeDiagnoses'] ?? [],
    );

    final prescriptions = List<dynamic>.from(
      _medicalSummary?['activePrescriptions'] ?? [],
    );

    final labReports = List<dynamic>.from(
      _medicalSummary?['recentLabReports'] ?? [],
    );

    final vaccinations = List<dynamic>.from(
      _medicalSummary?['recentVaccinations'] ?? [],
    );

    final procedures = List<dynamic>.from(
      _medicalSummary?['recentProcedures'] ?? [],
    );

    final imagingReports = List<dynamic>.from(
      _medicalSummary?['recentImagingReports'] ?? [],
    );

    final documents = List<dynamic>.from(
      _medicalSummary?['recentDocuments'] ?? [],
    );

    final latestVital = _medicalSummary?['latestVital'];

    final hasAnyRecords =
        diagnoses.isNotEmpty ||
        prescriptions.isNotEmpty ||
        labReports.isNotEmpty ||
        vaccinations.isNotEmpty ||
        procedures.isNotEmpty ||
        imagingReports.isNotEmpty ||
        documents.isNotEmpty ||
        latestVital != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // TITLE
          // ==================================================

          const Text(
            'Medical Records',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'View and manage your medical history.',
            style: TextStyle(
              fontSize: 14,
              color: Appcolors.secondaryText,
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================
          // SEARCH BAR
          // ==================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Appcolors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Appcolors.border,
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search medical records...',
                hintStyle: TextStyle(
                  color: Appcolors.secondaryText,
                ),
                border: InputBorder.none,
                icon: Icon(
                  Icons.search,
                  color: Appcolors.secondaryText,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==================================================
          // FILTER CHIPS
          // ==================================================

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(label: 'All'),

                const SizedBox(width: 10),

                _buildFilterChip(label: 'Diagnoses'),

                const SizedBox(width: 10),

                _buildFilterChip(label: 'Vitals'),

                const SizedBox(width: 10),

                _buildFilterChip(label: 'Documents'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================
          // SUMMARY
          // ==================================================

          _buildSummaryCards(totals),

          const SizedBox(height: 24),

          // ==================================================
          // RECORDS
          // ==================================================

          if (!hasAnyRecords)
            _buildEmptyState()
          else ...[
            // Diagnoses
            if ((selectedFilter == 'All' ||
                    selectedFilter == 'Diagnoses') &&
                diagnoses.isNotEmpty)
              _buildDiagnosisSection(diagnoses),

            // Vitals
            if ((selectedFilter == 'All' ||
                    selectedFilter == 'Vitals') &&
                latestVital != null)
              _buildVitalsSection(latestVital),

            // Documents
            if ((selectedFilter == 'All' ||
                    selectedFilter == 'Documents') &&
                (labReports.isNotEmpty ||
                    imagingReports.isNotEmpty ||
                    documents.isNotEmpty))
              _buildDocumentsSection(
                labReports,
                imagingReports,
                documents,
              ),

            // Prescriptions
            if (selectedFilter == 'All' &&
                prescriptions.isNotEmpty)
              _buildPrescriptionSection(
                prescriptions,
              ),

            // Vaccinations
            if (selectedFilter == 'All' &&
                vaccinations.isNotEmpty)
              _buildSimpleSection(
                title: 'Vaccinations',
                icon: Icons.vaccines_outlined,
                items: vaccinations,
              ),

            // Procedures
            if (selectedFilter == 'All' &&
                procedures.isNotEmpty)
              _buildSimpleSection(
                title: 'Procedures',
                icon: Icons.medical_services_outlined,
                items: procedures,
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards(
    Map<String, dynamic> totals,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            value: '${totals['diagnoses'] ?? 0}',
            label: 'Diagnoses',
            icon: Icons.medical_services_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildSummaryCard(
            value: '${totals['labReports'] ?? 0}',
            label: 'Lab Reports',
            icon: Icons.science_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Appcolors.primary,
            size: 24,
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Appcolors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Appcolors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              size: 42,
              color: Appcolors.primary,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No medical records yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your medical reports, diagnoses, prescriptions '
            'and other records will appear here when they '
            'are added by your healthcare provider.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Appcolors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIAGNOSES
  // ============================================================

  Widget _buildDiagnosisSection(
    List<dynamic> diagnoses,
  ) {
    final filtered = diagnoses.where((item) {
      return _matchesSearch(
        item.toString(),
      );
    }).toList();

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Diagnoses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Appcolors.primaryText,
          ),
        ),

        const SizedBox(height: 12),

        ...filtered.map(
          (diagnosis) => Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: _buildDiagnosisCard(
              diagnosis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisCard(
    dynamic diagnosis,
  ) {
    final diagnosisMap =
        diagnosis is Map
            ? Map<String, dynamic>.from(diagnosis)
            : <String, dynamic>{};

    final name =
        diagnosisMap['name'] ??
        diagnosisMap['diagnosis'] ??
        diagnosisMap['description'] ??
        diagnosisMap['diagnosisName'] ??
        'Diagnosis';

    final status =
        diagnosisMap['status'] ??
        'Active';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MedicalRecordDetailScreen(
              type: 'diagnosis',

              // Pass the ACTUAL backend record
              record: diagnosisMap,
            ),
          ),
        );
      },
      child: Container(
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    Appcolors.primary.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: Appcolors.primary,
                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.primaryText,
                    ),
                  ),

                  const SizedBox(height: 3),

                  const Text(
                    'Diagnosis',
                    style: TextStyle(
                      fontSize: 13,
                      color: Appcolors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color:
                    Appcolors.success.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                status.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Appcolors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VITALS
  // ============================================================

  Widget _buildVitalsSection(
    dynamic latestVital,
  ) {
    if (!_matchesSearch('Vitals')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Vitals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Appcolors.primaryText,
          ),
        ),

        const SizedBox(height: 12),

        _buildVitalsCard(latestVital),
      ],
    );
  }

  Widget _buildVitalsCard(
    dynamic latestVital,
  ) {
    final vital =
        latestVital is Map
            ? Map<String, dynamic>.from(latestVital)
            : <String, dynamic>{};

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MedicalRecordDetailScreen(
              type: 'vital',

              // Pass the ACTUAL backend vital
              record: vital,
            ),
          ),
        );
      },
      child: Container(
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
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        Appcolors.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_outline,
                    color: Appcolors.primary,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vitals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Appcolors.primaryText,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Latest recorded measurements',
                      style: TextStyle(
                        fontSize: 13,
                        color: Appcolors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                const Icon(
                  Icons.chevron_right,
                  color: Appcolors.secondaryText,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    label: 'Blood Pressure',
                    value:
                        vital['bloodPressure'] ??
                        vital['bp'] ??
                        '--',
                    unit: 'mmHg',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildVitalItem(
                    label: 'Heart Rate',
                    value:
                        vital['heartRate'] ??
                        '--',
                    unit: 'bpm',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    label: 'SpO₂',
                    value:
                        vital['spo2'] ??
                        vital['oxygenSaturation'] ??
                        '--',
                    unit: '%',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildVitalItem(
                    label: 'Temperature',
                    value:
                        vital['temperature'] ??
                        '--',
                    unit: '°C',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem({
    required String label,
    required dynamic value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Appcolors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Appcolors.secondaryText,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            unit,
            style: const TextStyle(
              fontSize: 11,
              color: Appcolors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENTS
  // ============================================================

  Widget _buildDocumentsSection(
    List<dynamic> labReports,
    List<dynamic> imagingReports,
    List<dynamic> documents,
  ) {
    final allDocuments = [
      ...labReports,
      ...imagingReports,
      ...documents,
    ];

    final filtered = allDocuments.where((item) {
      return _matchesSearch(
        item.toString(),
      );
    }).toList();

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Medical Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Appcolors.primaryText,
          ),
        ),

        const SizedBox(height: 12),

        ...filtered.map(
          (document) => Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: _buildDocumentCard(
              document,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(
    dynamic document,
  ) {
    final documentMap =
        document is Map
            ? Map<String, dynamic>.from(document)
            : <String, dynamic>{};

    final title =
        documentMap['title'] ??
        documentMap['name'] ??
        documentMap['reportName'] ??
        'Medical Document';

    final type =
        documentMap['type'] ??
        'Medical Record';

    final date =
        documentMap['date'] ??
        documentMap['createdAt'] ??
        '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
                  Appcolors.primary.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Appcolors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Appcolors.primaryText,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  type.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Appcolors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (date.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date.toString(),
                    style: const TextStyle(
                      fontSize: 11,
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

  // ============================================================
  // PRESCRIPTIONS
  // ============================================================

  Widget _buildPrescriptionSection(
    List<dynamic> prescriptions,
  ) {
    return _buildSimpleSection(
      title: 'Active Prescriptions',
      icon: Icons.medication_outlined,
      items: prescriptions,
    );
  }

  // ============================================================
  // SIMPLE SECTION
  // ============================================================

  Widget _buildSimpleSection({
    required String title,
    required IconData icon,
    required List<dynamic> items,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Appcolors.primaryText,
          ),
        ),

        const SizedBox(height: 12),

        ...items.map(
          (item) {
            final text =
                item is Map
                    ? (item['name'] ??
                        item['title'] ??
                        item['description'] ??
                        item.toString())
                    : item.toString();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Appcolors.surface,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: Appcolors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Appcolors.primary,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      text.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            Appcolors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  bool _matchesSearch(String text) {
    if (searchQuery.trim().isEmpty) {
      return true;
    }

    return text
        .toLowerCase()
        .contains(
          searchQuery.trim().toLowerCase(),
        );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _buildFilterChip({
    required String label,
  }) {
    final bool isSelected =
        selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Appcolors.primary
              : Appcolors.surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Appcolors.primary
                : Appcolors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : Appcolors.secondaryText,
          ),
        ),
      ),
    );
  }
}