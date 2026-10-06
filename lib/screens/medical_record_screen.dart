import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/patient_service.dart';
import '../utils/appcolors.dart';
import '../utils/auth_storage.dart';
import 'medical_record_detail_screen.dart';

class MedicalRecordScreen extends StatefulWidget {
  final String initialFilter;

  const MedicalRecordScreen({
    super.key,
    this.initialFilter = 'All',
  });

  @override
  State<MedicalRecordScreen> createState() =>
      _MedicalRecordScreenState();
}

class _MedicalRecordScreenState
    extends State<MedicalRecordScreen> {
  final PatientService _patientService = PatientService();
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  final TextEditingController _searchController =
      TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedFilter = 'All';
  String _searchQuery = '';

  Map<String, dynamic>? _summary;

  List<dynamic> _diagnoses = [];
  List<dynamic> _prescriptions = [];
  List<dynamic> _vitals = [];

  Map<String, dynamic>? _latestVital;

  List<dynamic> _documents = [];
  List<dynamic> _vaccinations = [];
  List<dynamic> _procedures = [];

  @override
  void initState() {
    super.initState();

    _selectedFilter = widget.initialFilter;

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
      });
    });

    _loadMedicalRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Load medical records
  // ─────────────────────────────────────────────

  Future<void> _loadMedicalRecords() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get logged-in patient's profile.
      final patientResponse =
          await _patientService.getMyPatientProfile();

      final patientData = patientResponse['data'];

      if (patientData == null ||
          patientData is! Map ||
          patientData['_id'] == null) {
        throw Exception(
          'Patient information could not be found.',
        );
      }

      final String patientId =
          patientData['_id'].toString();

      print('========== MEDICAL RECORDS ==========');
      print('PATIENT ID: $patientId');

      // ─────────────────────────────────────────
      // Medical history
      // ─────────────────────────────────────────

      final historyResponse =
          await _patientService.getMedicalHistory(
        patientId,
      );

      // Support both:
      //
      // {
      //   "data": {
      //     "diagnoses": [...]
      //   }
      // }
      //
      // and:
      //
      // {
      //   "diagnoses": [...]
      // }
      final dynamic rawHistory =
          historyResponse['data'];

      final Map<String, dynamic> historyData =
          rawHistory is Map
              ? Map<String, dynamic>.from(rawHistory)
              : historyResponse;

      final diagnoses = List<dynamic>.from(
        historyData['diagnoses'] ?? [],
      );

      final prescriptions = List<dynamic>.from(
        historyData['prescriptions'] ?? [],
      );

      final vitals = List<dynamic>.from(
        historyData['vitals'] ?? [],
      );

      final vaccinations = List<dynamic>.from(
        historyData['vaccinations'] ?? [],
      );

      final procedures = List<dynamic>.from(
        historyData['procedures'] ?? [],
      );

      // ─────────────────────────────────────────
      // REAL uploaded documents
      // ─────────────────────────────────────────
      //
      // IMPORTANT:
      // Do NOT use historyData['labReports'] or
      // historyData['imagingReports'] here.
      //
      // Those are medical-history records, not necessarily
      // Document collection IDs.
      //
      // The document viewer requires the actual Document
      // _id from:
      //
      // GET /patients/:patientId/documents
      //
      final documents =
          await _loadPatientDocuments(patientId);

      Map<String, dynamic>? latestVital;

      if (vitals.isNotEmpty) {
        final firstVital =
            _recordData(vitals.first);

        if (firstVital.isNotEmpty) {
          latestVital = firstVital;
        }
      }

      if (!mounted) return;

      setState(() {
        _summary = historyData;

        _diagnoses = diagnoses;
        _prescriptions = prescriptions;
        _vitals = vitals;

        _latestVital = latestVital;

        _documents = documents;
        _vaccinations = vaccinations;
        _procedures = procedures;

        _isLoading = false;
      });

      print('DOCUMENT COUNT: ${documents.length}');
      print('====================================');
    } catch (e, stackTrace) {
      print('========== MEDICAL RECORD ERROR ==========');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('==========================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ─────────────────────────────────────────────
  // Load actual patient documents
  // ─────────────────────────────────────────────

  Future<List<dynamic>> _loadPatientDocuments(
    String patientId,
  ) async {
    final token =
        await _authStorage.getAccessToken();

    if (token == null) {
      throw Exception(
        'No access token found.',
      );
    }

    final response = await _apiService.get(
      '/patients/$patientId/documents',
      token: token,
    );

    print('========== PATIENT DOCUMENTS ==========');
    print(
      'DOCUMENT STATUS: ${response.statusCode}',
    );
    print(
      'DOCUMENT RESPONSE: ${response.body}',
    );

    if (response.statusCode != 200) {
      try {
        final data =
            jsonDecode(response.body);

        final message =
            data['error']?['message'];

        throw Exception(
          message ??
              'Failed to load patient documents.',
        );
      } catch (e) {
        if (e is Exception &&
            e
                .toString()
                .contains(
                  'Failed to load patient documents',
                )) {
          rethrow;
        }

        throw Exception(
          'Failed to load patient documents.',
        );
      }
    }

    final decoded =
        jsonDecode(response.body);

    final dynamic rawDocuments =
        decoded['data'];

    List<dynamic> documents = [];

    if (rawDocuments is List) {
      documents =
          List<dynamic>.from(
        rawDocuments,
      );
    } else if (rawDocuments is Map) {
      documents =
          List<dynamic>.from(
        rawDocuments['documents'] ??
            rawDocuments['items'] ??
            [],
      );
    }

    print(
      'DOCUMENT COUNT: ${documents.length}',
    );

    for (final document in documents) {
      print(
        'DOCUMENT: $document',
      );

      if (document is Map) {
        print(
          '  ID: ${document['_id']}',
        );

        print(
          '  PATIENT ID: ${document['patientId']}',
        );

        print(
          '  NAME: ${document['originalName']}',
        );

        print(
          '  TITLE: ${document['documentTitle']}',
        );

        print(
          '  MIME: ${document['mimeType']}',
        );

        print(
          '  CATEGORY: ${document['category']}',
        );
      }
    }

    print(
      '=======================================',
    );

    return documents;
  }

  // ─────────────────────────────────────────────
  // Refresh
  // ─────────────────────────────────────────────

  Future<void> _refreshRecords() async {
    await _loadMedicalRecords();
  }

  // ─────────────────────────────────────────────
  // Safely unwrap medical record data
  // ─────────────────────────────────────────────

  Map<String, dynamic> _recordData(
    dynamic record,
  ) {
    if (record is! Map) {
      return {};
    }

    final map =
        Map<String, dynamic>.from(record);

    // Some medical records may be:
    //
    // {
    //   "_id": "...",
    //   "patientId": "...",
    //   "data": {
    //      "diagnosis": "..."
    //   }
    // }
    //
    // Keep BOTH the outer metadata and nested data.
    if (map['data'] is Map) {
      final nested =
          Map<String, dynamic>.from(
        map['data'],
      );

      return {
        ...map,
        ...nested,
      };
    }

    return map;
  }

  // ─────────────────────────────────────────────
  // Search
  // ─────────────────────────────────────────────

  bool _matchesSearch(
    dynamic record,
    List<String> fields,
  ) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final map =
        _recordData(record);

    if (map.isEmpty) {
      return false;
    }

    for (final field in fields) {
      final value = map[field];

      if (value != null &&
          value
              .toString()
              .toLowerCase()
              .contains(
                _searchQuery,
              )) {
        return true;
      }
    }

    return false;
  }

  List<dynamic>
      get _filteredDiagnoses {
    return _diagnoses.where(
      (diagnosis) {
        return _matchesSearch(
          diagnosis,
          [
            'diagnosis',
            'name',
            'condition',
            'description',
            'details',
            'notes',
            'code',
            'status',
          ],
        );
      },
    ).toList();
  }

  List<dynamic>
      get _filteredPrescriptions {
    return _prescriptions.where(
      (prescription) {
        return _matchesSearch(
          prescription,
          [
            'medicationName',
            'genericName',
            'medication',
            'drugName',
            'dosage',
            'frequency',
            'route',
            'duration',
            'instructions',
            'status',
          ],
        );
      },
    ).toList();
  }

  List<dynamic> get _filteredVitals {
    return _vitals.where(
      (vital) {
        return _matchesSearch(
          vital,
          [
            'bloodPressure',
            'systolic',
            'diastolic',
            'heartRate',
            'pulse',
            'temperature',
            'respiratoryRate',
            'oxygenSaturation',
            'spo2',
            'weight',
            'height',
            'bmi',
            'notes',
          ],
        );
      },
    ).toList();
  }

  List<dynamic>
      get _filteredDocuments {
    return _documents.where(
      (document) {
        return _matchesSearch(
          document,
          [
            'title',
            'documentTitle',
            'name',
            'reportName',
            'documentName',
            'type',
            'documentType',
            'description',
            'fileName',
            'originalName',
            'category',
            'sourceHospital',
          ],
        );
      },
    ).toList();
  }

  List<dynamic>
      get _filteredVaccinations {
    return _vaccinations.where(
      (vaccination) {
        return _matchesSearch(
          vaccination,
          [
            'name',
            'vaccineName',
            'vaccine',
            'type',
            'description',
            'status',
            'notes',
          ],
        );
      },
    ).toList();
  }

  List<dynamic>
      get _filteredProcedures {
    return _procedures.where(
      (procedure) {
        return _matchesSearch(
          procedure,
          [
            'name',
            'procedureName',
            'type',
            'description',
            'status',
            'notes',
          ],
        );
      },
    ).toList();
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Appcolors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:
            Appcolors.background,
        elevation: 0,
        title: const Text(
          'Medical Records',
          style: TextStyle(
            color: Appcolors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Appcolors.primaryText,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: Appcolors.primary,
        ),
      );
    }

    if (_errorMessage != null &&
        _summary == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _refreshRecords,
      color: Appcolors.primary,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          30,
        ),
        children: [
          _buildSearchBar(),

          const SizedBox(height: 16),

          _buildFilterChips(),

          const SizedBox(height: 20),

          _buildSummaryCards(),

          const SizedBox(height: 24),

          _buildRecordContent(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Search bar
  // ─────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration:
          BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: TextField(
        controller:
            _searchController,
        decoration:
            InputDecoration(
          hintText:
              'Search medical records...',
          hintStyle:
              const TextStyle(
            color:
                Appcolors.secondaryText,
          ),
          prefixIcon:
              const Icon(
            Icons.search,
            color:
                Appcolors.secondaryText,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController
                            .clear();
                      },
                      icon:
                          const Icon(
                        Icons.close,
                        color: Appcolors
                            .secondaryText,
                      ),
                    )
                  : null,
          border:
              InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Filters
  // ─────────────────────────────────────────────

  Widget _buildFilterChips() {
    final filters = [
      'All',
      'Diagnoses',
      'Prescriptions',
      'Vitals',
      'Documents',
      'Vaccinations',
      'Procedures',
    ];

    return SizedBox(
      height: 42,
      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            filters.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (context, index) {
          final filter =
              filters[index];

          final bool isSelected =
              _selectedFilter ==
                  filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter =
                    filter;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration:
                  BoxDecoration(
                color: isSelected
                    ? Appcolors
                        .primary
                    : Appcolors
                        .surface,
                borderRadius:
                    BorderRadius
                        .circular(
                  22,
                ),
                border:
                    Border.all(
                  color: isSelected
                      ? Appcolors
                          .primary
                      : Appcolors
                          .border,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Appcolors
                          .secondaryText,
                  fontWeight:
                      isSelected
                          ? FontWeight
                              .w600
                          : FontWeight
                              .w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Summary
  // ─────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child:
              _buildSummaryCard(
            title: 'Diagnoses',
            count:
                _diagnoses.length,
            icon: Icons
                .medical_information_outlined,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child:
              _buildSummaryCard(
            title:
                'Prescriptions',
            count:
                _prescriptions.length,
            icon: Icons
                .medication_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration:
                BoxDecoration(
              color: Appcolors
                  .primary
                  .withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color:
                  Appcolors.primary,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  count.toString(),
                  style:
                      const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight
                            .bold,
                    color: Appcolors
                        .primaryText,
                  ),
                ),
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Appcolors
                        .secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Record content
  // ─────────────────────────────────────────────

  Widget _buildRecordContent() {
    final List<Widget> sections =
        [];

    // Diagnoses
    if (_selectedFilter ==
            'All' ||
        _selectedFilter ==
            'Diagnoses') {
      if (_filteredDiagnoses
          .isNotEmpty) {
        sections.add(
          _buildSection(
            title: 'Diagnoses',
            icon: Icons
                .medical_information_outlined,
            children:
                _filteredDiagnoses
                    .map(
                      (diagnosis) =>
                          _buildDiagnosisCard(
                        diagnosis,
                      ),
                    )
                    .toList(),
          ),
        );
      }
    }

    // Prescriptions
    if (_selectedFilter ==
            'All' ||
        _selectedFilter ==
            'Prescriptions') {
      if (_filteredPrescriptions
          .isNotEmpty) {
        sections.add(
          _buildSection(
            title:
                'Prescriptions',
            icon: Icons
                .medication_outlined,
            children:
                _filteredPrescriptions
                    .map(
                      (prescription) =>
                          _buildPrescriptionCard(
                        prescription,
                      ),
                    )
                    .toList(),
          ),
        );
      }
    }

    // Vitals
    if (_selectedFilter ==
            'All' ||
        _selectedFilter ==
            'Vitals') {
      if (_selectedFilter ==
          'Vitals') {
        if (_filteredVitals
            .isNotEmpty) {
          sections.add(
            _buildSection(
              title:
                  'Vital Signs',
              icon: Icons
                  .monitor_heart_outlined,
              children:
                  _filteredVitals
                      .map(
                        (vital) =>
                            _buildVitalCard(
                          _recordData(
                            vital,
                          ),
                        ),
                      )
                      .toList(),
            ),
          );
        }
      } else if (_latestVital !=
          null) {
        final latestMatches =
            _matchesSearch(
          _latestVital,
          [
            'bloodPressure',
            'systolic',
            'diastolic',
            'heartRate',
            'pulse',
            'temperature',
            'respiratoryRate',
            'oxygenSaturation',
            'spo2',
            'weight',
            'height',
            'bmi',
            'notes',
          ],
        );

        if (latestMatches) {
          sections.add(
            _buildSection(
              title:
                  'Latest Vital',
              icon: Icons
                  .monitor_heart_outlined,
              children: [
                _buildVitalCard(
                  _latestVital!,
                ),
              ],
            ),
          );
        }
      }
    }

    // Documents
    if (_selectedFilter ==
            'All' ||
        _selectedFilter ==
            'Documents') {
      if (_filteredDocuments
          .isNotEmpty) {
        sections.add(
          _buildSection(
            title: 'Documents',
            icon: Icons
                .description_outlined,
            children:
                _filteredDocuments
                    .map(
                      (document) =>
                          _buildDocumentCard(
                        document,
                      ),
                    )
                    .toList(),
          ),
        );
      }
    }

    // Vaccinations
    if (_selectedFilter ==
            'All' ||
        _selectedFilter ==
            'Vaccinations') {
      if (_filteredVaccinations
          .isNotEmpty) {
        sections.add(
          _buildSection(
            title:
                'Vaccinations',
            icon: Icons
                .vaccines_outlined,
            children:
                _filteredVaccinations
                    .map(
                      (vaccination) =>
                          _buildGenericRecordCard(
                        vaccination,
                        Icons
                            .vaccines_outlined,
                      ),
                    )
                    .toList(),
          ),
        );
      }
    }

    // Procedures
    if (_selectedFilter ==
            'All' ||
        _selectedFilter ==
            'Procedures') {
      if (_filteredProcedures
          .isNotEmpty) {
        sections.add(
          _buildSection(
            title: 'Procedures',
            icon: Icons
                .healing_outlined,
            children:
                _filteredProcedures
                    .map(
                      (procedure) =>
                          _buildGenericRecordCard(
                        procedure,
                        Icons
                            .healing_outlined,
                      ),
                    )
                    .toList(),
          ),
        );
      }
    }

    if (sections.isEmpty) {
      return _buildEmptyState(
        title: _searchQuery.isEmpty
            ? 'No medical records yet'
            : 'No matching records',
        message:
            _searchQuery.isEmpty
                ? 'Your medical records will appear here when they are added.'
                : 'Try another search term or select a different filter.',
        icon:
            _searchQuery.isEmpty
                ? Icons
                    .folder_open_outlined
                : Icons
                    .search_off_outlined,
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
      children: sections
          .map(
            (section) =>
                Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 20,
              ),
              child: section,
            ),
          )
          .toList(),
    );
  }

  // ─────────────────────────────────────────────
  // Section
  // ─────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  Appcolors.primary,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: Appcolors
                    .primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        ...children,
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Diagnosis card
  // ─────────────────────────────────────────────

  Widget _buildDiagnosisCard(
    dynamic diagnosis,
  ) {
    final map =
        _recordData(diagnosis);

    final title =
        map['diagnosis'] ??
            map['name'] ??
            map['condition'] ??
            'Diagnosis';

    final description =
        map['description'] ??
            map['details'] ??
            map['notes'] ??
            '';

    final status =
        map['status']?.toString();

    return _buildRecordCard(
      icon: Icons
          .medical_information_outlined,
      title: title.toString(),
      subtitle:
          description.toString(),
      trailing: status,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MedicalRecordDetailScreen(
              type: 'diagnosis',
              record: diagnosis
                      is Map
                  ? Map<String,
                          dynamic>.from(
                      diagnosis,
                    )
                  : map,
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Prescription card
  // ─────────────────────────────────────────────

  Widget _buildPrescriptionCard(
    dynamic prescription,
  ) {
    final map =
        _recordData(
      prescription,
    );

    final medicationName =
        map['medicationName'] ??
            map['genericName'] ??
            map['medication'] ??
            map['drugName'] ??
            'Prescription';

    final genericName =
        map['genericName'];

    final dosage =
        map['dosage']?.toString();

    final frequency =
        map['frequency']?.toString();

    final bool isActive =
        map['isActive'] == true ||
        map['status']
                ?.toString()
                .toLowerCase() ==
            'active';

    return _buildRecordCard(
      icon: Icons
          .medication_outlined,
      title:
          medicationName.toString(),
      subtitle: [
        if (genericName != null &&
            genericName
                .toString()
                .isNotEmpty &&
            genericName.toString() !=
                medicationName
                    .toString())
          genericName.toString(),
        if (dosage != null &&
            dosage.isNotEmpty)
          dosage,
        if (frequency != null &&
            frequency.isNotEmpty)
          frequency,
      ].join(' • '),
      trailing: isActive
          ? 'Active'
          : 'Inactive',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MedicalRecordDetailScreen(
              type: 'prescription',
              record: prescription
                      is Map
                  ? Map<String,
                          dynamic>.from(
                      prescription,
                    )
                  : map,
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Vital card
  // ─────────────────────────────────────────────

  Widget _buildVitalCard(
    Map<String, dynamic> vital,
  ) {
    final bloodPressure =
        vital['bloodPressure']
            ?.toString();

    final heartRate =
        vital['heartRate'] ??
            vital['pulse'];

    final temperature =
        vital['temperature'];

    final oxygen =
        vital['oxygenSaturation'] ??
            vital['spo2'];

    final weight =
        vital['weight'];

    final parts = <String>[];

    if (bloodPressure != null &&
        bloodPressure.isNotEmpty) {
      parts.add(
        'BP: $bloodPressure',
      );
    }

    if (heartRate != null) {
      parts.add(
        'HR: $heartRate',
      );
    }

    if (temperature != null) {
      parts.add(
        'Temp: $temperature',
      );
    }

    if (oxygen != null) {
      parts.add(
        'SpO₂: $oxygen',
      );
    }

    if (weight != null) {
      parts.add(
        'Weight: $weight',
      );
    }

    return _buildRecordCard(
      icon: Icons
          .monitor_heart_outlined,
      title: 'Vital Signs',
      subtitle: parts.isEmpty
          ? 'View vital sign details'
          : parts.join(' • '),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MedicalRecordDetailScreen(
              type: 'vital',
              record: vital,
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Document card
  // ─────────────────────────────────────────────

  Widget _buildDocumentCard(
    dynamic document,
  ) {
    final documentMap =
        _recordData(document);

    final title =
        documentMap['documentTitle'] ??
            documentMap['title'] ??
            documentMap['name'] ??
            documentMap['reportName'] ??
            documentMap['documentName'] ??
            documentMap['originalName'] ??
            documentMap['fileName'] ??
            'Medical Document';

    final type =
        documentMap['category'] ??
            documentMap['documentType'] ??
            documentMap['type'] ??
            documentMap['mimeType'] ??
            'Document';

    final date =
        documentMap['documentDate'] ??
            documentMap['date'] ??
            documentMap['createdAt'] ??
            documentMap['uploadedAt'] ??
            '';

    return GestureDetector(
      onTap: () {
        final documentId =
            documentMap['_id'];

        print(
          '========== OPEN DOCUMENT =========='
        );
        print(
          'DOCUMENT ID: $documentId',
        );
        print(
          'PATIENT ID: ${documentMap['patientId']}',
        );
        print(
          'DOCUMENT: $document',
        );
        print(
          '====================================',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MedicalRecordDetailScreen(
              type: 'document',
              record: document
                      is Map
                  ? Map<String,
                          dynamic>.from(
                      document,
                    )
                  : documentMap,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(
          16,
        ),
        decoration:
            BoxDecoration(
          color: Appcolors.surface,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Appcolors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                color: Appcolors
                    .primary
                    .withValues(
                  alpha: 0.1,
                ),
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
              child: const Icon(
                Icons
                    .description_outlined,
                color:
                    Appcolors.primary,
                size: 24,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title.toString(),
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                      color: Appcolors
                          .primaryText,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    type.toString(),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Appcolors.primary,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  if (date
                      .toString()
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      date.toString(),
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color: Appcolors
                            .secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color:
                  Appcolors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Generic record card
  // ─────────────────────────────────────────────

  Widget _buildGenericRecordCard(
    dynamic record,
    IconData icon,
  ) {
    final map =
        _recordData(record);

    final title =
        map['name'] ??
            map['title'] ??
            map['vaccineName'] ??
            map['procedureName'] ??
            map['type'] ??
            'Medical Record';

    final subtitle =
        map['description'] ??
            map['notes'] ??
            map['date'] ??
            map['administeredAt'] ??
            map['performedAt'] ??
            '';

    return _buildRecordCard(
      icon: icon,
      title: title.toString(),
      subtitle:
          subtitle.toString(),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MedicalRecordDetailScreen(
              type: 'generic',
              record: record is Map
                  ? Map<String,
                          dynamic>.from(
                      record,
                    )
                  : map,
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Standard record card
  // ─────────────────────────────────────────────

  Widget _buildRecordCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
          BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          height: 44,
          width: 44,
          decoration:
              BoxDecoration(
            color: Appcolors
                .primary
                .withValues(
              alpha: 0.1,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color:
                Appcolors.primary,
          ),
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
            color:
                Appcolors.primaryText,
          ),
        ),
        subtitle:
            subtitle.isNotEmpty
                ? Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 4,
                    ),
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        color: Appcolors
                            .secondaryText,
                      ),
                    ),
                  )
                : null,
        trailing:
            trailing != null
                ? Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color: trailing
                                  .toLowerCase() ==
                              'active'
                          ? Appcolors
                              .success
                              .withValues(
                              alpha: 0.1,
                            )
                          : Appcolors
                              .secondaryText
                              .withValues(
                              alpha: 0.1,
                            ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child: Text(
                      trailing,
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color: trailing
                                    .toLowerCase() ==
                                'active'
                            ? Appcolors
                                .success
                            : Appcolors
                                .secondaryText,
                      ),
                    ),
                  )
                : onTap != null
                    ? const Icon(
                        Icons.chevron_right,
                        color: Appcolors
                            .secondaryText,
                      )
                    : null,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        30,
      ),
      decoration:
          BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration:
                BoxDecoration(
              color: Appcolors
                  .primary
                  .withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 34,
              color:
                  Appcolors.primary,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
              color:
                  Appcolors.primaryText,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 14,
              color:
                  Appcolors.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Error state
  // ─────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color:
                  Appcolors.error,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Could not load medical records',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Appcolors.primaryText,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Appcolors
                    .secondaryText,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed:
                  _loadMedicalRecords,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Appcolors.primary,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}