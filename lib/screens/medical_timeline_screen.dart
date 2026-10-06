import 'package:flutter/material.dart';

import '../services/patient_service.dart';
import '../utils/appcolors.dart';

import 'medical_record_detail_screen.dart';

class MedicalTimelineScreen extends StatefulWidget {
  const MedicalTimelineScreen({super.key});

  @override
  State<MedicalTimelineScreen> createState() =>
      _MedicalTimelineScreenState();
}

class _MedicalTimelineScreenState
    extends State<MedicalTimelineScreen> {
  final PatientService _patientService = PatientService();

  bool _isLoading = true;
  String? _error;

  List<_TimelineEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // ------------------------------------------------------------
      // 1. Get logged-in patient's profile
      // ------------------------------------------------------------
      final patientResponse =
          await _patientService.getMyPatientProfile();

      final patientData = patientResponse['data'];

      if (patientData == null) {
        throw Exception(
          'Patient data was not returned by the server.',
        );
      }

      final patient =
          Map<String, dynamic>.from(patientData);

      final patientId =
          patient['_id']?.toString() ??
          patient['patientId']?.toString();

      if (patientId == null || patientId.isEmpty) {
        throw Exception(
          'Patient ID was not found.',
        );
      }

      // ------------------------------------------------------------
      // 2. Get complete medical history
      // ------------------------------------------------------------
      final historyResponse =
          await _patientService.getMedicalHistory(
        patientId,
      );

      // Backend returns the grouped history directly:
      //
      // {
      //   encounters: [],
      //   diagnoses: [],
      //   vitals: [],
      //   clinicalNotes: [],
      //   prescriptions: [],
      //   labReports: [],
      //   imagingReports: [],
      //   vaccinations: [],
      //   procedures: []
      // }
      //
      // We also support a possible { data: {...} } wrapper.

      final historyData =
          historyResponse['data'] is Map
              ? Map<String, dynamic>.from(
                  historyResponse['data'],
                )
              : historyResponse;

      final events = <_TimelineEvent>[];

      // ------------------------------------------------------------
      // Diagnoses
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['diagnoses'],
        type: 'diagnosis',
      );

      // ------------------------------------------------------------
      // Vitals
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['vitals'],
        type: 'vitals',
      );

      // ------------------------------------------------------------
      // Encounters
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['encounters'],
        type: 'encounter',
      );

      // ------------------------------------------------------------
      // Clinical notes
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['clinicalNotes'],
        type: 'clinical_note',
      );

      // ------------------------------------------------------------
      // Prescriptions
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['prescriptions'],
        type: 'prescription',
      );

      // ------------------------------------------------------------
      // Lab reports
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['labReports'],
        type: 'lab_report',
      );

      // ------------------------------------------------------------
      // Imaging
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['imagingReports'],
        type: 'imaging',
      );

      // ------------------------------------------------------------
      // Vaccinations
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['vaccinations'],
        type: 'vaccination',
      );

      // ------------------------------------------------------------
      // Procedures
      // ------------------------------------------------------------
      _addEvents(
        events,
        historyData['procedures'],
        type: 'procedure',
      );

      // ------------------------------------------------------------
      // Sort newest → oldest
      // ------------------------------------------------------------
      events.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print('MEDICAL TIMELINE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error =
            'Failed to load your medical timeline.';
      });
    }
  }

  void _addEvents(
    List<_TimelineEvent> events,
    dynamic records, {
    required String type,
  }) {
    if (records is! List) return;

    for (final item in records) {
      if (item is! Map) continue;

      final record =
          Map<String, dynamic>.from(item);

      final date = _extractDate(
        record,
        type,
      );

      if (date == null) {
        continue;
      }

      final display =
          _buildDisplayData(
        record,
        type,
      );

      events.add(
        _TimelineEvent(
          type: type,
          record: record,
          date: date,
          icon: display.icon,
          title: display.title,
          subtitle: display.subtitle,
          details: display.details,
        ),
      );
    }
  }

  DateTime? _extractDate(
    Map<String, dynamic> record,
    String type,
  ) {
    final data =
        record['data'] is Map
            ? Map<String, dynamic>.from(
                record['data'],
              )
            : record;

    final possibleDates = <dynamic>[];

    switch (type) {
      case 'diagnosis':
        possibleDates.addAll([
          data['diagnosedAt'],
          data['diagnosisDate'],
          record['createdAt'],
        ]);
        break;

      case 'vitals':
        possibleDates.addAll([
          data['recordedAt'],
          data['measuredAt'],
          record['createdAt'],
        ]);
        break;

      case 'encounter':
        possibleDates.addAll([
          data['encounterDate'],
          data['date'],
          record['createdAt'],
        ]);
        break;

      case 'clinical_note':
        possibleDates.addAll([
          data['createdAt'],
          record['createdAt'],
        ]);
        break;

      case 'prescription':
        possibleDates.addAll([
          data['prescribedAt'],
          data['startDate'],
          record['createdAt'],
        ]);
        break;

      case 'lab_report':
        possibleDates.addAll([
          data['reportDate'],
          data['reportedAt'],
          record['createdAt'],
        ]);
        break;

      case 'imaging':
        possibleDates.addAll([
          data['reportDate'],
          record['createdAt'],
        ]);
        break;

      case 'vaccination':
        possibleDates.addAll([
          data['administeredAt'],
          data['administeredDate'],
          record['createdAt'],
        ]);
        break;

      case 'procedure':
        possibleDates.addAll([
          data['performedAt'],
          data['performedDate'],
          record['createdAt'],
        ]);
        break;
    }

    for (final value in possibleDates) {
      if (value == null) continue;

      final parsed = DateTime.tryParse(
        value.toString(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  _TimelineDisplayData _buildDisplayData(
    Map<String, dynamic> record,
    String type,
  ) {
    final data =
        record['data'] is Map
            ? Map<String, dynamic>.from(
                record['data'],
              )
            : record;

    switch (type) {
      case 'diagnosis':
        final diagnosisName =
            data['diagnosisName']?.toString() ??
                data['name']?.toString() ??
                data['diagnosis']?.toString() ??
                'Diagnosis';

        final code =
            data['diagnosisCode']?.toString() ??
                data['icdCode']?.toString();

        final status =
            data['status']?.toString();

        return _TimelineDisplayData(
          icon: Icons.medical_services_outlined,
          title: diagnosisName,
          subtitle: code != null
              ? 'Diagnosis • $code'
              : 'Diagnosis',
          details: status != null
              ? 'Status: ${_prettyText(status)}'
              : 'Medical diagnosis recorded',
        );

      case 'vitals':
        final systolic =
            data['bloodPressureSystolic'];

        final diastolic =
            data['bloodPressureDiastolic'];

        final heartRate =
            data['heartRate'];

        final oxygen =
            data['oxygenSaturation'];

        final temperature =
            data['temperature'];

        final bp =
            systolic != null && diastolic != null
                ? 'Blood Pressure $systolic/$diastolic'
                : null;

        final hr =
            heartRate != null
                ? 'Heart Rate $heartRate'
                : null;

        final spo2 =
            oxygen != null
                ? 'SpO₂ $oxygen%'
                : null;

        final temp =
            temperature != null
                ? 'Temperature $temperature °C'
                : null;

        final values = [
          bp,
          hr,
          spo2,
          temp,
        ].whereType<String>().toList();

        return _TimelineDisplayData(
          icon: Icons.favorite_outline,
          title: 'Vitals Recorded',
          subtitle: values.isNotEmpty
              ? values.take(2).join(' • ')
              : 'Vital signs',
          details: values.length > 2
              ? values.skip(2).join(' • ')
              : 'Vital signs recorded',
        );

      case 'encounter':
        final encounterType =
            data['encounterType']?.toString() ??
                data['type']?.toString();

        final complaint =
            data['chiefComplaint']?.toString();

        return _TimelineDisplayData(
          icon: Icons.local_hospital_outlined,
          title: 'Medical Visit',
          subtitle: encounterType != null
              ? _prettyText(encounterType)
              : 'Medical Encounter',
          details: complaint != null &&
                  complaint.isNotEmpty
              ? complaint
              : 'Medical encounter recorded',
        );

      case 'clinical_note':
        final title =
            data['title']?.toString() ??
                'Clinical Note';

        final noteType =
            data['noteType']?.toString();

        final content =
            data['content']?.toString();

        return _TimelineDisplayData(
          icon: Icons.description_outlined,
          title: title,
          subtitle: noteType != null
              ? _prettyText(noteType)
              : 'Clinical Note',
          details: content != null &&
                  content.isNotEmpty
              ? _shorten(content)
              : 'Clinical note recorded',
        );

      case 'prescription':
        final medication =
            data['medicationName']?.toString() ??
                data['medicineName']?.toString() ??
                'Prescription';

        final dosage =
            data['dosage']?.toString();

        final frequency =
            data['frequency']?.toString();

        final parts = [
          dosage,
          frequency,
        ].whereType<String>().toList();

        return _TimelineDisplayData(
          icon: Icons.medication_outlined,
          title: medication,
          subtitle: parts.isNotEmpty
              ? parts.join(' • ')
              : 'Prescription',
          details: 'Medication prescribed',
        );

      case 'lab_report':
        final testName =
            data['testName']?.toString() ??
                'Laboratory Test';

        final status =
            data['status']?.toString();

        final interpretation =
            data['interpretation']?.toString();

        return _TimelineDisplayData(
          icon: Icons.science_outlined,
          title: testName,
          subtitle: status != null
              ? 'Lab Report • ${_prettyText(status)}'
              : 'Lab Report',
          details: interpretation != null &&
                  interpretation.isNotEmpty
              ? interpretation
              : 'Laboratory report recorded',
        );

      case 'imaging':
        final imagingType =
            data['imagingType']?.toString() ??
                'Imaging Report';

        final bodyPart =
            data['bodyPart']?.toString();

        final impression =
            data['impression']?.toString();

        return _TimelineDisplayData(
          icon: Icons.image_outlined,
          title: imagingType,
          subtitle: bodyPart != null
              ? 'Imaging • $bodyPart'
              : 'Imaging Report',
          details: impression != null &&
                  impression.isNotEmpty
              ? impression
              : 'Medical imaging document',
        );

      case 'vaccination':
        final vaccine =
            data['vaccineName']?.toString() ??
                'Vaccination';

        final dose =
            data['dose']?.toString();

        return _TimelineDisplayData(
          icon: Icons.vaccines_outlined,
          title: vaccine,
          subtitle: dose != null
              ? 'Vaccination • Dose $dose'
              : 'Vaccination',
          details: 'Vaccination recorded',
        );

      case 'procedure':
        final procedure =
            data['procedureName']?.toString() ??
                'Medical Procedure';

        final status =
            data['status']?.toString();

        final outcome =
            data['outcome']?.toString();

        return _TimelineDisplayData(
          icon: Icons.healing_outlined,
          title: procedure,
          subtitle: status != null
              ? 'Procedure • ${_prettyText(status)}'
              : 'Procedure',
          details: outcome != null &&
                  outcome.isNotEmpty
              ? outcome
              : 'Medical procedure recorded',
        );
    }

    return _TimelineDisplayData(
      icon: Icons.medical_information_outlined,
      title: 'Medical Record',
      subtitle: 'Medical Event',
      details: 'Medical record entry',
    );
  }

  String _prettyText(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _shorten(String value) {
    final clean = value.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (clean.length <= 90) {
      return clean;
    }

    return '${clean.substring(0, 87)}...';
  }

  String _formatDate(DateTime date) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color:
                      Appcolors.primary.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timeline_outlined,
                  color: Appcolors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Could not load timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Appcolors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Appcolors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadTimeline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTimeline,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            30,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 70),
            Icon(
              Icons.timeline_outlined,
              size: 64,
              color: Appcolors.secondaryText
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 18),
            Text(
              'No medical history yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Appcolors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your medical events will appear here when they are recorded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Appcolors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimeline,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          30,
        ),
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          ..._buildGroupedTimeline(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Timeline',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Appcolors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A chronological view of your medical history.',
          style: TextStyle(
            fontSize: 14,
            color: Appcolors.secondaryText,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedTimeline() {
    final widgets = <Widget>[];

    DateTime? currentDate;

    for (int i = 0; i < _events.length; i++) {
      final event = _events[i];

      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      final isNewDate =
          currentDate == null ||
          currentDate != eventDate;

      if (isNewDate) {
        if (widgets.isNotEmpty) {
          widgets.add(
            const SizedBox(height: 16),
          );
        }

        widgets.add(
          _buildDateHeader(
            _formatDate(event.date),
          ),
        );

        widgets.add(
          const SizedBox(height: 14),
        );

        currentDate = eventDate;
      }

      final isLast =
          i == _events.length - 1 ||
          _dateOnly(_events[i + 1].date) !=
              _dateOnly(event.date);

      widgets.add(
        _buildTimelineItem(
          context: context,
          event: event,
          isLast: isLast,
        ),
      );
    }

    return widgets;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  Widget _buildDateHeader(String date) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Appcolors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          date,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Appcolors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required _TimelineEvent event,
    required bool isLast,
  }) {
    final canOpenDetails =
        event.type == 'diagnosis' ||
        event.type == 'vitals';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 10,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 16,
                  color:
                      Appcolors.primary.withValues(
                    alpha: 0.35,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Appcolors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color:
                          Appcolors.primary.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: canOpenDetails
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MedicalRecordDetailScreen(
                            type: event.type,
                            record: event.record,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(
                  bottom: 14,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Appcolors.surface,
                  borderRadius:
                      BorderRadius.circular(18),
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
                            Appcolors.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        event.icon,
                        color: Appcolors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Appcolors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Appcolors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.details,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Appcolors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (canOpenDetails)
                      Icon(
                        Icons.chevron_right,
                        color:
                            Appcolors.secondaryText,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Timeline models
// -----------------------------------------------------------------------------

class _TimelineEvent {
  final String type;
  final Map<String, dynamic> record;
  final DateTime date;
  final IconData icon;
  final String title;
  final String subtitle;
  final String details;

  const _TimelineEvent({
    required this.type,
    required this.record,
    required this.date,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.details,
  });
}

class _TimelineDisplayData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String details;

  const _TimelineDisplayData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.details,
  });
}