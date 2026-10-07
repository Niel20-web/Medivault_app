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

  // ===========================================================================
  // LOAD TIMELINE
  // ===========================================================================

  Future<void> _loadTimeline() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // -----------------------------------------------------------------------
      // 1. Get the currently logged-in patient
      // -----------------------------------------------------------------------

      final patientResponse =
          await _patientService.getMyPatientProfile();

      final patient = _unwrapResponse(
        patientResponse,
      );

      // IMPORTANT:
      // The history endpoint expects the backend UUID (_id).
      // Do not use profileId or MV-2026-xxxxx here.
      final patientId = patient['_id']?.toString();

      if (patientId == null || patientId.trim().isEmpty) {
        throw Exception(
          'Patient ID was not found.',
        );
      }

      // -----------------------------------------------------------------------
      // 2. Get complete medical history
      // -----------------------------------------------------------------------

      final historyResponse =
          await _patientService.getMedicalHistory(
        patientId,
      );

      final historyData =
          _unwrapResponse(historyResponse);

      final events = <_TimelineEvent>[];

      // -----------------------------------------------------------------------
      // 3. Add all supported history categories
      // -----------------------------------------------------------------------

      _addEvents(
        events,
        historyData['diagnoses'],
        type: 'diagnosis',
      );

      _addEvents(
        events,
        historyData['vitals'],
        type: 'vitals',
      );

      _addEvents(
        events,
        historyData['encounters'],
        type: 'encounter',
      );

      _addEvents(
        events,
        historyData['clinicalNotes'],
        type: 'clinical_note',
      );

      _addEvents(
        events,
        historyData['prescriptions'],
        type: 'prescription',
      );

      _addEvents(
        events,
        historyData['labReports'],
        type: 'lab_report',
      );

      _addEvents(
        events,
        historyData['imagingReports'],
        type: 'imaging',
      );

      _addEvents(
        events,
        historyData['vaccinations'],
        type: 'vaccination',
      );

      _addEvents(
        events,
        historyData['procedures'],
        type: 'procedure',
      );

      // -----------------------------------------------------------------------
      // 4. Newest → oldest
      // -----------------------------------------------------------------------

      events.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'MEDICAL TIMELINE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _events = [];
        _error =
            'Failed to load your medical timeline.';
      });
    }
  }

  // ===========================================================================
  // RESPONSE HELPERS
  // ===========================================================================

  Map<String, dynamic> _unwrapResponse(
    Map<String, dynamic> response,
  ) {
    final dynamic data = response['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  Map<String, dynamic> _recordData(
    Map<String, dynamic> record,
  ) {
    final dynamic nestedData = record['data'];

    if (nestedData is Map) {
      return {
        ...record,
        ...Map<String, dynamic>.from(nestedData),
      };
    }

    return record;
  }

  String? _stringValue(
    dynamic value,
  ) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
  }

  // ===========================================================================
  // ADD EVENTS
  // ===========================================================================

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

  // ===========================================================================
  // DATE HANDLING
  // ===========================================================================

  DateTime? _extractDate(
    Map<String, dynamic> record,
    String type,
  ) {
    final data = _recordData(record);

    final possibleDates = <dynamic>[];

    switch (type) {
      case 'diagnosis':
        possibleDates.addAll([
          data['diagnosedAt'],
          data['diagnosisDate'],
          data['date'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'vitals':
        possibleDates.addAll([
          data['recordedAt'],
          data['measuredAt'],
          data['recordedDate'],
          data['date'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'encounter':
        possibleDates.addAll([
          data['encounterDate'],
          data['visitDate'],
          data['date'],
          data['startedAt'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'clinical_note':
        possibleDates.addAll([
          data['createdAt'],
          data['noteDate'],
          data['date'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'prescription':
        possibleDates.addAll([
          data['prescribedAt'],
          data['startDate'],
          data['prescriptionDate'],
          data['date'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'lab_report':
        possibleDates.addAll([
          data['reportDate'],
          data['resultedAt'],
          data['reportedAt'],
          data['date'],
          data['collectedAt'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'imaging':
        possibleDates.addAll([
          data['reportDate'],
          data['performedAt'],
          data['performedDate'],
          data['date'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'vaccination':
        possibleDates.addAll([
          data['administeredAt'],
          data['administeredDate'],
          data['vaccinationDate'],
          data['date'],
          record['createdAt'],
          record['updatedAt'],
        ]);
        break;

      case 'procedure':
        possibleDates.addAll([
          data['performedAt'],
          data['performedDate'],
          data['procedureDate'],
          data['date'],
          record['createdAt'],
          record['updatedAt'],
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

  // ===========================================================================
  // DISPLAY DATA
  // ===========================================================================

  _TimelineDisplayData _buildDisplayData(
    Map<String, dynamic> record,
    String type,
  ) {
    final data = _recordData(record);

    switch (type) {
      // -----------------------------------------------------------------------
      // DIAGNOSIS
      // -----------------------------------------------------------------------

      case 'diagnosis':
        final diagnosisName =
            _stringValue(
                  data['diagnosisName'],
                ) ??
                _stringValue(
                  data['diagnosis'],
                ) ??
                _stringValue(
                  data['name'],
                ) ??
                _stringValue(
                  data['condition'],
                ) ??
                _stringValue(
                  data['title'],
                ) ??
                'Diagnosis';

        final code =
            _stringValue(
                  data['diagnosisCode'],
                ) ??
                _stringValue(
                  data['icdCode'],
                ) ??
                _stringValue(
                  data['code'],
                );

        final status =
            _stringValue(
              data['status'],
            );

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

      // -----------------------------------------------------------------------
      // VITALS
      // -----------------------------------------------------------------------

      case 'vitals':
        final systolic =
            data['bloodPressureSystolic'];

        final diastolic =
            data['bloodPressureDiastolic'];

        final bloodPressure =
            _stringValue(
              data['bloodPressure'],
            ) ??
            _stringValue(
              data['bp'],
            );

        final heartRate =
            _stringValue(
              data['heartRate'],
            ) ??
            _stringValue(
              data['pulse'],
            );

        final oxygen =
            _stringValue(
              data['oxygenSaturation'],
            ) ??
            _stringValue(
              data['spo2'],
            ) ??
            _stringValue(
              data['oxygen'],
            );

        final temperature =
            _stringValue(
              data['temperature'],
            ) ??
            _stringValue(
              data['temp'],
            );

        final weight =
            _stringValue(
              data['weight'],
            );

        final height =
            _stringValue(
              data['height'],
            );

        String? bp;

        if (systolic != null &&
            diastolic != null) {
          bp =
              'Blood Pressure $systolic/$diastolic';
        } else if (bloodPressure != null) {
          bp =
              'Blood Pressure $bloodPressure';
        }

        final hr = heartRate != null
            ? 'Heart Rate $heartRate'
            : null;

        final spo2 = oxygen != null
            ? 'SpO₂ $oxygen%'
            : null;

        final temp = temperature != null
            ? 'Temperature $temperature °C'
            : null;

        final weightText = weight != null
            ? 'Weight $weight'
            : null;

        final heightText = height != null
            ? 'Height $height'
            : null;

        final values = [
          bp,
          hr,
          spo2,
          temp,
          weightText,
          heightText,
        ].whereType<String>().toList();

        return _TimelineDisplayData(
          icon: Icons.favorite_outline,
          title: 'Vitals Recorded',
          subtitle: values.isNotEmpty
              ? values.take(2).join(' • ')
              : 'Vital signs',
          details: values.length > 2
              ? values.skip(2).take(3).join(' • ')
              : 'Vital signs recorded',
        );

      // -----------------------------------------------------------------------
      // ENCOUNTER
      // -----------------------------------------------------------------------

      case 'encounter':
        final encounterType =
            _stringValue(
                  data['encounterType'],
                ) ??
                _stringValue(
                  data['type'],
                ) ??
                _stringValue(
                  data['visitType'],
                );

        final complaint =
            _stringValue(
              data['chiefComplaint'],
            ) ??
            _stringValue(
              data['reason'],
            ) ??
            _stringValue(
              data['complaint'],
            );

        return _TimelineDisplayData(
          icon: Icons.local_hospital_outlined,
          title: 'Medical Visit',
          subtitle: encounterType != null
              ? _prettyText(encounterType)
              : 'Medical Encounter',
          details: complaint != null
              ? complaint
              : 'Medical encounter recorded',
        );

      // -----------------------------------------------------------------------
      // CLINICAL NOTE
      // -----------------------------------------------------------------------

      case 'clinical_note':
        final title =
            _stringValue(
                  data['title'],
                ) ??
                _stringValue(
                  data['noteTitle'],
                ) ??
                'Clinical Note';

        final noteType =
            _stringValue(
              data['noteType'],
            );

        final content =
            _stringValue(
                  data['content'],
                ) ??
                _stringValue(
                  data['note'],
                ) ??
                _stringValue(
                  data['text'],
                );

        return _TimelineDisplayData(
          icon: Icons.description_outlined,
          title: title,
          subtitle: noteType != null
              ? _prettyText(noteType)
              : 'Clinical Note',
          details: content != null
              ? _shorten(content)
              : 'Clinical note recorded',
        );

      // -----------------------------------------------------------------------
      // PRESCRIPTION
      // -----------------------------------------------------------------------

      case 'prescription':
        final medication =
            _stringValue(
                  data['medicationName'],
                ) ??
                _stringValue(
                  data['medicineName'],
                ) ??
                _stringValue(
                  data['name'],
                ) ??
                _stringValue(
                  data['medicine'],
                ) ??
                _stringValue(
                  data['drugName'],
                ) ??
                'Prescription';

        final dosage =
            _stringValue(
                  data['dosage'],
                ) ??
                _stringValue(
                  data['dose'],
                );

        final frequency =
            _stringValue(
                  data['frequency'],
                ) ??
                _stringValue(
                  data['doseFrequency'],
                ) ??
                _stringValue(
                  data['schedule'],
                );

        final duration =
            _stringValue(
                  data['duration'],
                ) ??
                _stringValue(
                  data['treatmentDuration'],
                );

        final status =
            _stringValue(
                  data['status'],
                ) ??
                _stringValue(
                  data['prescriptionStatus'],
                );

        final parts = [
          dosage,
          frequency,
        ].whereType<String>().toList();

        String details =
            'Medication prescribed';

        if (duration != null) {
          details =
              'Duration: $duration';
        }

        if (status != null) {
          details =
              '${_prettyText(status)}${duration != null ? ' • $duration' : ''}';
        }

        return _TimelineDisplayData(
          icon: Icons.medication_outlined,
          title: medication,
          subtitle: parts.isNotEmpty
              ? parts.join(' • ')
              : 'Prescription',
          details: details,
        );

      // -----------------------------------------------------------------------
      // LAB REPORT
      // -----------------------------------------------------------------------

      case 'lab_report':
        final testName =
            _stringValue(
                  data['testName'],
                ) ??
                _stringValue(
                  data['name'],
                ) ??
                'Laboratory Test';

        final status =
            _stringValue(
                  data['status'],
                ) ??
                _stringValue(
                  data['resultStatus'],
                );

        final result =
            _stringValue(
                  data['results'],
                ) ??
                _stringValue(
                  data['result'],
                );

        final interpretation =
            _stringValue(
              data['interpretation'],
            );

        String details =
            'Laboratory report recorded';

        if (interpretation != null) {
          details = interpretation;
        } else if (result != null) {
          details = 'Result: $result';
        }

        return _TimelineDisplayData(
          icon: Icons.science_outlined,
          title: testName,
          subtitle: status != null
              ? 'Lab Report • ${_prettyText(status)}'
              : 'Lab Report',
          details: details,
        );

      // -----------------------------------------------------------------------
      // IMAGING
      // -----------------------------------------------------------------------

      case 'imaging':
        final imagingType =
            _stringValue(
                  data['imagingType'],
                ) ??
                _stringValue(
                  data['type'],
                ) ??
                _stringValue(
                  data['modality'],
                ) ??
                'Imaging Report';

        final bodyPart =
            _stringValue(
              data['bodyPart'],
            );

        final impression =
            _stringValue(
                  data['impression'],
                ) ??
                _stringValue(
                  data['findings'],
                );

        return _TimelineDisplayData(
          icon: Icons.image_outlined,
          title: imagingType,
          subtitle: bodyPart != null
              ? 'Imaging • $bodyPart'
              : 'Imaging Report',
          details: impression != null
              ? _shorten(impression)
              : 'Medical imaging document',
        );

      // -----------------------------------------------------------------------
      // VACCINATION
      // -----------------------------------------------------------------------

      case 'vaccination':
        final vaccine =
            _stringValue(
                  data['vaccineName'],
                ) ??
                _stringValue(
                  data['vaccine'],
                ) ??
                _stringValue(
                  data['name'],
                ) ??
                'Vaccination';

        final dose =
            _stringValue(
              data['dose'],
            );

        final manufacturer =
            _stringValue(
              data['manufacturer'],
            );

        String details =
            'Vaccination recorded';

        if (manufacturer != null) {
          details =
              'Manufacturer: $manufacturer';
        }

        return _TimelineDisplayData(
          icon: Icons.vaccines_outlined,
          title: vaccine,
          subtitle: dose != null
              ? 'Vaccination • Dose $dose'
              : 'Vaccination',
          details: details,
        );

      // -----------------------------------------------------------------------
      // PROCEDURE
      // -----------------------------------------------------------------------

      case 'procedure':
        final procedure =
            _stringValue(
                  data['procedureName'],
                ) ??
                _stringValue(
                  data['name'],
                ) ??
                _stringValue(
                  data['procedure'],
                ) ??
                'Medical Procedure';

        final status =
            _stringValue(
              data['status'],
            );

        final outcome =
            _stringValue(
                  data['outcome'],
                ) ??
                _stringValue(
                  data['result'],
                );

        return _TimelineDisplayData(
          icon: Icons.healing_outlined,
          title: procedure,
          subtitle: status != null
              ? 'Procedure • ${_prettyText(status)}'
              : 'Procedure',
          details: outcome != null
              ? _shorten(outcome)
              : 'Medical procedure recorded',
        );
    }

    return const _TimelineDisplayData(
      icon: Icons.medical_information_outlined,
      title: 'Medical Record',
      subtitle: 'Medical Event',
      details: 'Medical record entry',
    );
  }

  // ===========================================================================
  // TEXT HELPERS
  // ===========================================================================

  String _prettyText(
    String value,
  ) {
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _shorten(
    String value,
  ) {
    final clean = value
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    if (clean.length <= 90) {
      return clean;
    }

    return '${clean.substring(0, 87)}...';
  }

  String _formatDate(
    DateTime date,
  ) {
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Appcolors.primary,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: Appcolors.primary,
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
          const SizedBox(height: 28),
          ..._buildGroupedTimeline(),
        ],
      ),
    );
  }

  // ===========================================================================
  // ERROR STATE
  // ===========================================================================

  Widget _buildErrorState() {
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
                backgroundColor:
                    Appcolors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: Appcolors.primary,
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

  // ===========================================================================
  // HEADER
  // ===========================================================================

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

  // ===========================================================================
  // GROUPED TIMELINE
  // ===========================================================================

  List<Widget> _buildGroupedTimeline() {
    final widgets = <Widget>[];

    DateTime? currentDate;

    for (
      int i = 0;
      i < _events.length;
      i++
    ) {
      final event = _events[i];

      final eventDate =
          _dateOnly(event.date);

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

      final bool isLast =
          i == _events.length - 1 ||
          _dateOnly(
                _events[i + 1].date,
              ) !=
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

  // ===========================================================================
  // DATE HEADER
  // ===========================================================================

  Widget _buildDateHeader(
    String date,
  ) {
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

  // ===========================================================================
  // TIMELINE ITEM
  // ===========================================================================

  Widget _buildTimelineItem({
    required BuildContext context,
    required _TimelineEvent event,
    required bool isLast,
  }) {
    final canOpenDetails =
        _canOpenDetails(event.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------------
          // Timeline line
          // -------------------------------------------------------------------

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

          // -------------------------------------------------------------------
          // Event card
          // -------------------------------------------------------------------

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 14,
              ),
              child: Material(
                color: Appcolors.surface,
                borderRadius:
                    BorderRadius.circular(18),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(18),
                  onTap: canOpenDetails
                      ? () =>
                          _openDetails(event)
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.all(16),
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
                          width: 44,
                          height: 44,
                          decoration:
                              BoxDecoration(
                            color: Appcolors.primary
                                .withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(12),
                          ),
                          child: Icon(
                            event.icon,
                            color:
                                Appcolors.primary,
                            size: 22,
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
                                event.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color: Appcolors
                                      .primaryText,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                event.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color: Appcolors
                                      .primary,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                event.details,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Appcolors
                                      .secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canOpenDetails)
                          const SizedBox(width: 6),
                        if (canOpenDetails)
                          Icon(
                            Icons.chevron_right,
                            color: Appcolors
                                .secondaryText,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DETAIL NAVIGATION
  // ===========================================================================

  bool _canOpenDetails(
    String type,
  ) {
    switch (type) {
      case 'diagnosis':
      case 'vitals':
      case 'prescription':
      case 'lab_report':
      case 'encounter':
      case 'clinical_note':
      case 'imaging':
      case 'vaccination':
      case 'procedure':
        return true;

      default:
        return false;
    }
  }

  void _openDetails(
    _TimelineEvent event,
  ) {
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
}

// =============================================================================
// TIMELINE MODELS
// =============================================================================

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