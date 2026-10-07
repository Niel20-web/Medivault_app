import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/patient_service.dart';
import '../utils/appcolors.dart';
import '../utils/auth_storage.dart';
import 'lab_reports_screen.dart';
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

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  final PatientService _patientService = PatientService();
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  final TextEditingController _searchController =
      TextEditingController();

  static const List<String> _filters = [
    'All',
    'Diagnoses',
    'Prescriptions',
    'Vitals',
    'Lab Reports',
    'Documents',
    'Vaccinations',
    'Procedures',
  ];

  static const List<String> _diagnosisSearchFields = [
    'diagnosis',
    'diagnosisName',
    'name',
    'displayName',
    'title',
    'condition',
    'description',
    'details',
    'notes',
    'code',
    'status',
  ];

  static const List<String> _prescriptionSearchFields = [
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
  ];

  static const List<String> _vitalSearchFields = [
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
  ];

  static const List<String> _documentSearchFields = [
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
  ];

  static const List<String> _vaccinationSearchFields = [
    'name',
    'vaccineName',
    'vaccine',
    'type',
    'description',
    'status',
    'notes',
  ];

  static const List<String> _procedureSearchFields = [
    'name',
    'procedureName',
    'type',
    'description',
    'status',
    'notes',
  ];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedFilter = 'All';
  String _searchQuery = '';

  Map<String, dynamic>? _summary;

  List<dynamic> _diagnoses = [];
  List<dynamic> _prescriptions = [];
  List<dynamic> _vitals = [];
  List<dynamic> _documents = [];
  List<dynamic> _vaccinations = [];
  List<dynamic> _procedures = [];

  Map<String, dynamic>? _latestVital;

  @override
  void initState() {
    super.initState();

    _selectedFilter = _filters.contains(widget.initialFilter)
        ? widget.initialFilter
        : 'All';

    _searchController.addListener(_onSearchChanged);

    _loadMedicalRecords();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _onSearchChanged() {
    if (!mounted) return;

    final query = _searchController.text.trim().toLowerCase();

    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
    });
  }

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> _unwrapResponse(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  Map<String, dynamic> _recordData(dynamic record) {
    final map = _asMap(record);

    if (map.isEmpty) return {};

    final nestedData = map['data'];

    if (nestedData is Map) {
      return {
        ...map,
        ...Map<String, dynamic>.from(nestedData),
      };
    }

    return map;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    return [];
  }

  String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  String _getDisplayValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is String ||
        value is num ||
        value is bool) {
      return _stringValue(
        value,
        fallback: fallback,
      );
    }

    if (value is Map) {
      final map = _asMap(value);

      const nestedKeys = [
        'name',
        'diagnosisName',
        'displayName',
        'title',
        'label',
        'condition',
        'description',
        'code',
      ];

      for (final key in nestedKeys) {
        final nestedValue = map[key];

        if (nestedValue != null) {
          final result = _getDisplayValue(
            nestedValue,
            fallback: '',
          );

          if (result.isNotEmpty) {
            return result;
          }
        }
      }
    }

    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Load records
  // ---------------------------------------------------------------------------

  Future<void> _loadMedicalRecords() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final patientResponse =
          await _patientService.getMyPatientProfile();

      final patientData =
          _unwrapResponse(patientResponse);

      final patientId =
          _stringValue(patientData['_id']);

      if (patientId.isEmpty) {
        throw Exception(
          'Patient information could not be found.',
        );
      }

      final historyResponse =
          await _patientService.getMedicalHistory(
        patientId,
      );

      final historyData =
          _unwrapResponse(historyResponse);

      final diagnoses =
          _asList(historyData['diagnoses']);

      final prescriptions =
          _asList(historyData['prescriptions']);

      final vitals =
          _asList(historyData['vitals']);

      final vaccinations =
          _asList(historyData['vaccinations']);

      final procedures =
          _asList(historyData['procedures']);

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
        _documents = documents;
        _vaccinations = vaccinations;
        _procedures = procedures;

        _latestVital = latestVital;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

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

    if (response.statusCode != 200) {
      try {
        final decoded =
            jsonDecode(response.body);

        final errorData =
            decoded is Map ? decoded['error'] : null;

        final message =
            errorData is Map
                ? errorData['message']
                : null;

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

    if (decoded is! Map) {
      return [];
    }

    final rawDocuments =
        decoded['data'];

    if (rawDocuments is List) {
      return List<dynamic>.from(
        rawDocuments,
      );
    }

    if (rawDocuments is Map) {
      return _asList(
        rawDocuments['documents'] ??
            rawDocuments['items'],
      );
    }

    return [];
  }

  Future<void> _refreshRecords() async {
    await _loadMedicalRecords();
  }

  // ---------------------------------------------------------------------------
  // Search matching
  // ---------------------------------------------------------------------------

  bool _matchesSearch(
    dynamic record,
    List<String> fields,
  ) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final map = _recordData(record);

    if (map.isEmpty) {
      return false;
    }

    for (final field in fields) {
      final value = map[field];

      if (value == null) continue;

      final rawValue =
          value.toString().toLowerCase();

      if (rawValue.contains(_searchQuery)) {
        return true;
      }

      final displayValue =
          _getDisplayValue(value).toLowerCase();

      if (displayValue.contains(_searchQuery)) {
        return true;
      }
    }

    return false;
  }

  List<dynamic> _filterRecords(
    List<dynamic> records,
    List<String> fields,
  ) {
    return records
        .where(
          (record) =>
              _matchesSearch(record, fields),
        )
        .toList();
  }

  List<dynamic> get _filteredDiagnoses =>
      _filterRecords(
        _diagnoses,
        _diagnosisSearchFields,
      );

  List<dynamic> get _filteredPrescriptions =>
      _filterRecords(
        _prescriptions,
        _prescriptionSearchFields,
      );

  List<dynamic> get _filteredVitals =>
      _filterRecords(
        _vitals,
        _vitalSearchFields,
      );

  List<dynamic> get _filteredDocuments =>
      _filterRecords(
        _documents,
        _documentSearchFields,
      );

  List<dynamic> get _filteredVaccinations =>
      _filterRecords(
        _vaccinations,
        _vaccinationSearchFields,
      );

  List<dynamic> get _filteredProcedures =>
      _filterRecords(
        _procedures,
        _procedureSearchFields,
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Appcolors.background,
        elevation: 0,
        title: const Text(
          'Medical Records',
          style: TextStyle(
            color: Appcolors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Appcolors.primaryText,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
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
        padding: const EdgeInsets.fromLTRB(
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

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText:
              'Search medical records...',
          hintStyle: const TextStyle(
            color: Appcolors.secondaryText,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Appcolors.secondaryText,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed:
                          _searchController.clear,
                      icon: const Icon(
                        Icons.close,
                        color:
                            Appcolors.secondaryText,
                      ),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected =
              _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              if (isSelected) return;

              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Appcolors.primary
                    : Appcolors.surface,
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Appcolors.primary
                      : Appcolors.border,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Appcolors.secondaryText,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Diagnoses',
            count: _diagnoses.length,
            icon:
                Icons.medical_information_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Prescriptions',
            count: _prescriptions.length,
            icon: Icons.medication_outlined,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Appcolors.primary.withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Appcolors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Appcolors.primaryText,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Appcolors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Record content
  // ---------------------------------------------------------------------------

  Widget _buildRecordContent() {
    final sections = <Widget>[];

    _addSectionIf(
      sections,
      enabled: _selectedFilter == 'All' ||
          _selectedFilter == 'Diagnoses',
      records: _filteredDiagnoses,
      title: 'Diagnoses',
      icon:
          Icons.medical_information_outlined,
      builder: _buildDiagnosisCard,
    );

    _addSectionIf(
      sections,
      enabled: _selectedFilter == 'All' ||
          _selectedFilter == 'Prescriptions',
      records: _filteredPrescriptions,
      title: 'Prescriptions',
      icon: Icons.medication_outlined,
      builder: _buildPrescriptionCard,
    );

    _addVitalsSection(sections);

    if (_selectedFilter == 'All' ||
        _selectedFilter == 'Lab Reports') {
      sections.add(
        _buildLabReportsSection(),
      );
    }

    _addSectionIf(
      sections,
      enabled: _selectedFilter == 'All' ||
          _selectedFilter == 'Documents',
      records: _filteredDocuments,
      title: 'Documents',
      icon: Icons.description_outlined,
      builder: _buildDocumentCard,
    );

    _addSectionIf(
      sections,
      enabled: _selectedFilter == 'All' ||
          _selectedFilter == 'Vaccinations',
      records: _filteredVaccinations,
      title: 'Vaccinations',
      icon: Icons.vaccines_outlined,
      builder: (record) =>
          _buildGenericRecordCard(
        record,
        Icons.vaccines_outlined,
      ),
    );

    _addSectionIf(
      sections,
      enabled: _selectedFilter == 'All' ||
          _selectedFilter == 'Procedures',
      records: _filteredProcedures,
      title: 'Procedures',
      icon: Icons.healing_outlined,
      builder: (record) =>
          _buildGenericRecordCard(
        record,
        Icons.healing_outlined,
      ),
    );

    if (sections.isEmpty) {
      return _buildEmptyState(
        title: _searchQuery.isEmpty
            ? 'No medical records yet'
            : 'No matching records',
        message: _searchQuery.isEmpty
            ? 'Your medical records will appear here when they are added.'
            : 'Try another search term or select a different filter.',
        icon: _searchQuery.isEmpty
            ? Icons.folder_open_outlined
            : Icons.search_off_outlined,
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: sections
          .map(
            (section) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 20,
              ),
              child: section,
            ),
          )
          .toList(),
    );
  }

  void _addSectionIf(
    List<Widget> sections, {
    required bool enabled,
    required List<dynamic> records,
    required String title,
    required IconData icon,
    required Widget Function(dynamic) builder,
  }) {
    if (!enabled || records.isEmpty) return;

    sections.add(
      _buildSection(
        title: title,
        icon: icon,
        children: records
            .map(builder)
            .toList(),
      ),
    );
  }

  void _addVitalsSection(
    List<Widget> sections,
  ) {
    final showVitals =
        _selectedFilter == 'All' ||
            _selectedFilter == 'Vitals';

    if (!showVitals) return;

    if (_selectedFilter == 'Vitals') {
      _addSectionIf(
        sections,
        enabled: true,
        records: _filteredVitals,
        title: 'Vital Signs',
        icon:
            Icons.monitor_heart_outlined,
        builder: (vital) =>
            _buildVitalCard(
          _recordData(vital),
        ),
      );

      return;
    }

    if (_latestVital == null) return;

    final latestMatches =
        _matchesSearch(
      _latestVital,
      _vitalSearchFields,
    );

    if (!latestMatches) return;

    sections.add(
      _buildSection(
        title: 'Latest Vital',
        icon:
            Icons.monitor_heart_outlined,
        children: [
          _buildVitalCard(
            _latestVital!,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lab reports
  // ---------------------------------------------------------------------------

  Widget _buildLabReportsSection() {
    return _buildSection(
      title: 'Lab Reports',
      icon: Icons.science_outlined,
      children: [
        Material(
          color: Appcolors.surface,
          borderRadius:
              BorderRadius.circular(18),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const LabReportsScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: Appcolors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Appcolors.primary
                          .withValues(
                        alpha: 0.1,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color:
                          Appcolors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Laboratory Reports',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                            color: Appcolors
                                .primaryText,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'View your laboratory test results',
                          style: TextStyle(
                            fontSize: 13,
                            color: Appcolors
                                .secondaryText,
                          ),
                        ),
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
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section
  // ---------------------------------------------------------------------------

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Appcolors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    Appcolors.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _openDetail({
    required String type,
    required dynamic record,
  }) {
    final map = _recordData(record);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicalRecordDetailScreen(
          type: type,
          record: record is Map
              ? Map<String, dynamic>.from(
                  record,
                )
              : map,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Diagnosis
  // ---------------------------------------------------------------------------

  Widget _buildDiagnosisCard(
    dynamic diagnosis,
  ) {
    final map = _recordData(diagnosis);

    final title = _firstDisplayValue(
      map,
      [
        'diagnosis',
        'diagnosisName',
        'name',
        'displayName',
        'title',
        'condition',
      ],
      fallback: 'Diagnosis',
    );

    final description = _firstDisplayValue(
      map,
      [
        'description',
        'details',
        'notes',
      ],
    );

    final status =
        _getDisplayValue(map['status']);

    return _buildRecordCard(
      icon:
          Icons.medical_information_outlined,
      title: title,
      subtitle: description,
      trailing:
          status.isNotEmpty ? status : null,
      onTap: () => _openDetail(
        type: 'diagnosis',
        record: diagnosis,
      ),
    );
  }

  String _firstDisplayValue(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value =
          _getDisplayValue(map[key]);

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Prescription
  // ---------------------------------------------------------------------------

  Widget _buildPrescriptionCard(
    dynamic prescription,
  ) {
    final map =
        _recordData(prescription);

    final medicationName =
        _firstDisplayValue(
      map,
      [
        'medicationName',
        'medicineName',
        'medication',
        'drugName',
        'name',
        'genericName',
      ],
      fallback: 'Prescription',
    );

    final genericName =
        _stringValue(map['genericName']);

    final dosage =
        _stringValue(
      map['dosage'] ?? map['dose'],
    );

    final frequency =
        _stringValue(
      map['frequency'] ??
          map['doseFrequency'] ??
          map['schedule'],
    );

    final subtitleParts = <String>[];

    if (genericName.isNotEmpty &&
        genericName != medicationName) {
      subtitleParts.add(genericName);
    }

    if (dosage.isNotEmpty) {
      subtitleParts.add(dosage);
    }

    if (frequency.isNotEmpty) {
      subtitleParts.add(frequency);
    }

    final isActive =
        _isPrescriptionActive(map);

    return _buildRecordCard(
      icon: Icons.medication_outlined,
      title: medicationName,
      subtitle:
          subtitleParts.join(' • '),
      trailing:
          isActive ? 'Active' : 'Inactive',
      onTap: () => _openDetail(
        type: 'prescription',
        record: prescription,
      ),
    );
  }

  bool _isPrescriptionActive(
    Map<String, dynamic> prescription,
  ) {
    final rawIsActive =
        prescription['isActive'];

    if (rawIsActive is bool) {
      return rawIsActive;
    }

    if (rawIsActive is String) {
      final value =
          rawIsActive.toLowerCase().trim();

      if (_activeStatuses.contains(value)) {
        return true;
      }

      if (_inactiveStatuses.contains(value)) {
        return false;
      }
    }

    final status =
        _stringValue(
      prescription['status'] ??
          prescription['prescriptionStatus'],
    ).toLowerCase();

    if (_activeStatuses.contains(status)) {
      return true;
    }

    if (_inactiveStatuses.contains(status)) {
      return false;
    }

    final endDate =
        prescription['endedAt'] ??
            prescription['expiresAt'] ??
            prescription['endDate'];

    if (endDate != null) {
      try {
        final date =
            DateTime.parse(
          endDate.toString(),
        );

        if (date.isBefore(DateTime.now())) {
          return false;
        }
      } catch (_) {
        // Ignore invalid dates and fall back
        // to the default active state.
      }
    }

    return true;
  }

  static const Set<String> _activeStatuses = {
    'true',
    'active',
    'ongoing',
    'current',
    'in_progress',
    'in progress',
  };

  static const Set<String> _inactiveStatuses = {
    'false',
    'ended',
    'inactive',
    'completed',
    'cancelled',
    'canceled',
    'stopped',
    'discontinued',
    'expired',
  };

  // ---------------------------------------------------------------------------
  // Vitals
  // ---------------------------------------------------------------------------

  Widget _buildVitalCard(
    Map<String, dynamic> vital,
  ) {
    final bloodPressure =
        _stringValue(
      vital['bloodPressure'] ??
          vital['bp'],
    );

    final heartRate =
        vital['heartRate'] ??
            vital['pulse'];

    final temperature =
        vital['temperature'] ??
            vital['temp'];

    final oxygen =
        vital['oxygenSaturation'] ??
            vital['spo2'];

    final weight =
        vital['weight'];

    final parts = <String>[];

    if (bloodPressure.isNotEmpty) {
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
      icon:
          Icons.monitor_heart_outlined,
      title: 'Vital Signs',
      subtitle: parts.isEmpty
          ? 'View vital sign details'
          : parts.join(' • '),
      onTap: () => _openDetail(
        type: 'vital',
        record: vital,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Documents
  // ---------------------------------------------------------------------------

  Widget _buildDocumentCard(
    dynamic document,
  ) {
    final map =
        _recordData(document);

    final title = _firstDisplayValue(
      map,
      [
        'documentTitle',
        'title',
        'name',
        'reportName',
        'documentName',
        'originalName',
        'fileName',
      ],
      fallback: 'Medical Document',
    );

    final type = _firstDisplayValue(
      map,
      [
        'category',
        'documentType',
        'type',
        'mimeType',
      ],
      fallback: 'Document',
    );

    final date = _firstDisplayValue(
      map,
      [
        'documentDate',
        'date',
        'createdAt',
        'uploadedAt',
      ],
    );

    return _buildDocumentContainer(
      title: title,
      type: type,
      date: date,
      onTap: () => _openDetail(
        type: 'document',
        record: document,
      ),
    );
  }

  Widget _buildDocumentContainer({
    required String title,
    required String type,
    required String date,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(18),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Appcolors.primary
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
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
                        type,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Appcolors.primary,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          date,
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
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Generic records
  // ---------------------------------------------------------------------------

  Widget _buildGenericRecordCard(
    dynamic record,
    IconData icon,
  ) {
    final map =
        _recordData(record);

    final title = _firstDisplayValue(
      map,
      [
        'name',
        'title',
        'vaccineName',
        'procedureName',
        'type',
      ],
      fallback: 'Medical Record',
    );

    final subtitle = _firstDisplayValue(
      map,
      [
        'description',
        'notes',
        'date',
        'administeredAt',
        'performedAt',
      ],
    );

    return _buildRecordCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => _openDetail(
        type: 'generic',
        record: record,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Standard card
  // ---------------------------------------------------------------------------

  Widget _buildRecordCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Appcolors.primary
                  .withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Appcolors.primary,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  Appcolors.primaryText,
            ),
          ),
          subtitle: subtitle.isNotEmpty
              ? Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 4,
                  ),
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color: Appcolors
                          .secondaryText,
                    ),
                  ),
                )
              : null,
          trailing: trailing != null
              ? _buildStatusBadge(trailing)
              : onTap != null
                  ? const Icon(
                      Icons.chevron_right,
                      color: Appcolors
                          .secondaryText,
                    )
                  : null,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    String status,
  ) {
    final isActive =
        status.toLowerCase() == 'active';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Appcolors.success.withValues(
                alpha: 0.1,
              )
            : Appcolors.secondaryText
                .withValues(
                alpha: 0.1,
              ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive
              ? Appcolors.success
              : Appcolors.secondaryText,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Appcolors.primary
                  .withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 34,
              color: Appcolors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  Appcolors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Appcolors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load medical records',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Appcolors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    Appcolors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
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
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}