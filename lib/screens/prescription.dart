import 'package:flutter/material.dart';

import '../services/patient_service.dart';
import '../utils/appcolors.dart';
import 'medical_record_detail_screen.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final PatientService _patientService = PatientService();

  List<Map<String, dynamic>> _prescriptions = [];

  bool _isLoading = true;
  String? _error;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRESCRIPTIONS
  // ============================================================

  Future<void> _loadPrescriptions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final patientResponse =
          await _patientService.getMyPatientProfile();

      final dynamic rawPatient =
          patientResponse['data'];

      final Map<String, dynamic> patientData =
          rawPatient is Map
              ? Map<String, dynamic>.from(rawPatient)
              : Map<String, dynamic>.from(patientResponse);

      final dynamic rawPatientId =
          patientData['_id'];

      if (rawPatientId == null ||
          rawPatientId.toString().trim().isEmpty) {
        throw Exception(
          'Patient ID was not returned by the server.',
        );
      }

      // IMPORTANT:
      // Use the backend UUID (_id), not profileId.
      final String patientId =
          rawPatientId.toString().trim();

      debugPrint(
        'PRESCRIPTIONS PATIENT UUID: $patientId',
      );

      final historyResponse =
          await _patientService.getMedicalHistory(
        patientId,
      );

      final dynamic rawHistoryData =
          historyResponse['data'];

      final Map<String, dynamic> historyData =
          rawHistoryData is Map
              ? Map<String, dynamic>.from(rawHistoryData)
              : Map<String, dynamic>.from(historyResponse);

      final dynamic rawPrescriptions =
          historyData['prescriptions'];

      final List<Map<String, dynamic>>
          loadedPrescriptions = [];

      if (rawPrescriptions is List) {
        for (final item in rawPrescriptions) {
          if (item is Map) {
            loadedPrescriptions.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _prescriptions = loadedPrescriptions;
        _isLoading = false;
        _error = null;
      });

      debugPrint(
        'PRESCRIPTIONS LOADED: '
        '${loadedPrescriptions.length}',
      );
    } catch (e) {
      debugPrint(
        'PRESCRIPTIONS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
        _prescriptions = [];
      });
    }
  }

  // ============================================================
  // RECORD DATA
  // ============================================================

  Map<String, dynamic> _recordData(
    Map<String, dynamic> record,
  ) {
    final dynamic nestedData =
        record['data'];

    if (nestedData is Map) {
      return {
        ...record,
        ...Map<String, dynamic>.from(
          nestedData,
        ),
      };
    }

    return record;
  }

  // ============================================================
  // STRING HELPERS
  // ============================================================

  String? _stringValue(dynamic value) {
    if (value == null ||
        value is Map ||
        value is List) {
      return null;
    }

    final result =
        value.toString().trim();

    if (result.isEmpty ||
        result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  String _normalizedStatus(dynamic value) {
    return _stringValue(value)
            ?.toLowerCase()
            .trim() ??
        '';
  }

  // ============================================================
  // ACTIVE STATUS
  // ============================================================

  bool _isActive(
    Map<String, dynamic> prescription,
  ) {
    final data = _recordData(prescription);

    // ----------------------------------------------------------
    // 1. Explicit isActive takes priority
    // ----------------------------------------------------------

    final dynamic isActive =
        data['isActive'];

    if (isActive is bool) {
      return isActive;
    }

    if (isActive is String) {
      final value =
          isActive.toLowerCase().trim();

      if (value == 'true' ||
          value == 'active' ||
          value == 'ongoing' ||
          value == 'current') {
        return true;
      }

      if (value == 'false' ||
          value == 'inactive' ||
          value == 'ended' ||
          value == 'completed' ||
          value == 'cancelled' ||
          value == 'canceled' ||
          value == 'stopped' ||
          value == 'discontinued' ||
          value == 'expired') {
        return false;
      }
    }

    // ----------------------------------------------------------
    // 2. Explicit status takes priority over dates
    // ----------------------------------------------------------

    final String status =
        _normalizedStatus(
      data['status'] ??
          data['prescriptionStatus'],
    );

    const activeStatuses = {
      'active',
      'ongoing',
      'current',
      'in_progress',
      'in progress',
    };

    const endedStatuses = {
      'ended',
      'inactive',
      'completed',
      'cancelled',
      'canceled',
      'stopped',
      'discontinued',
      'expired',
    };

    if (activeStatuses.contains(status)) {
      return true;
    }

    if (endedStatuses.contains(status)) {
      return false;
    }

    // ----------------------------------------------------------
    // 3. End date is only a fallback
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

      if (parsedDate != null &&
          parsedDate.isBefore(
            DateTime.now(),
          )) {
        return false;
      }
    }

    // ----------------------------------------------------------
    // 4. Unknown = active/visible
    // ----------------------------------------------------------

    return true;
  }

  // ============================================================
  // MEDICINE NAME
  // ============================================================

  String _getMedicineName(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['medicationName'] ??
        data['medicineName'] ??
        data['medicine'] ??
        data['medication'] ??
        data['drugName'] ??
        data['drug'] ??
        data['productName'] ??
        data['name'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
            nested['name'] ??
                nested['medicationName'] ??
                nested['medicineName'] ??
                nested['drugName'] ??
                nested['displayName'] ??
                nested['title'],
          ) ??
          'Prescription';
    }

    return _stringValue(value) ??
        'Prescription';
  }

  // ============================================================
  // GENERIC NAME
  // ============================================================

  String? _getGenericName(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['genericName'] ??
        data['generic'] ??
        data['genericDrugName'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
        nested['name'] ??
            nested['genericName'] ??
            nested['displayName'],
      );
    }

    return _stringValue(value);
  }

  // ============================================================
  // DOSE
  // ============================================================

  String _getDose(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['dosage'] ??
        data['dose'] ??
        data['dosageInstruction'] ??
        data['doseInstruction'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
            nested['value'] ??
                nested['text'] ??
                nested['amount'] ??
                nested['dose'] ??
                nested['quantity'],
          ) ??
          'Dosage not specified';
    }

    return _stringValue(value) ??
        'Dosage not specified';
  }

  // ============================================================
  // FREQUENCY
  // ============================================================

  String _getFrequency(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['frequency'] ??
        data['frequencyText'] ??
        data['schedule'] ??
        data['frequencyInstruction'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
            nested['text'] ??
                nested['value'] ??
                nested['frequency'] ??
                nested['schedule'],
          ) ??
          'Frequency not specified';
    }

    return _stringValue(value) ??
        'Frequency not specified';
  }

  // ============================================================
  // ROUTE
  // ============================================================

  String? _getRoute(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['route'] ??
        data['administrationRoute'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
        nested['name'] ??
            nested['text'] ??
            nested['value'],
      );
    }

    return _stringValue(value);
  }

  // ============================================================
  // DURATION
  // ============================================================

  String? _getDuration(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['duration'] ??
        data['treatmentDuration'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
        nested['text'] ??
            nested['value'] ??
            nested['duration'],
      );
    }

    return _stringValue(value);
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  String? _getQuantity(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['quantity'] ??
        data['amount'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
        nested['value'] ??
            nested['amount'] ??
            nested['quantity'],
      );
    }

    return _stringValue(value);
  }

  // ============================================================
  // REFILLS
  // ============================================================

  String? _getRefills(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['refills'] ??
        data['refillCount'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(value);

      return _stringValue(
        nested['count'] ??
            nested['value'] ??
            nested['refills'],
      );
    }

    return _stringValue(value);
  }

  // ============================================================
  // PRESCRIBED BY
  // ============================================================

  String _getPrescribedBy(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final String? authorName =
        _stringValue(
      data['authorName'],
    );

    if (authorName != null) {
      return authorName;
    }

    final dynamic doctor =
        data['doctor'] ??
        data['doctorName'] ??
        data['prescribedBy'] ??
        data['provider'] ??
        data['prescriber'] ??
        data['physician'] ??
        data['orderedBy'];

    if (doctor is Map) {
      final doctorMap =
          Map<String, dynamic>.from(doctor);

      final String? name =
          _stringValue(
        doctorMap['name'] ??
            doctorMap['fullName'] ??
            doctorMap['displayName'] ??
            doctorMap['doctorName'] ??
            doctorMap['providerName'],
      );

      if (name != null) {
        return name;
      }

      final firstName =
          _stringValue(
        doctorMap['firstName'],
      );

      final lastName =
          _stringValue(
        doctorMap['lastName'],
      );

      final combined = [
        firstName,
        lastName,
      ].whereType<String>().join(' ');

      if (combined.isNotEmpty) {
        return combined;
      }
    }

    return _stringValue(doctor) ??
        'Healthcare provider';
  }

  // ============================================================
  // AUTHOR ROLE
  // ============================================================

  String? _getAuthorRole(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    return _stringValue(
      data['authorRole'] ??
          data['providerRole'] ??
          data['prescriberRole'],
    );
  }

  // ============================================================
  // END REASON
  // ============================================================

  String? _getEndReason(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    return _stringValue(
      data['endReason'] ??
          data['terminationReason'] ??
          data['stopReason'],
    );
  }

  // ============================================================
  // ENDED DATE
  // ============================================================

  String? _getEndedDate(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['endedAt'] ??
        data['endDate'] ??
        data['expiresAt'] ??
        data['stopDate'];

    if (value == null) {
      return null;
    }

    return _formatDate(value);
  }

  // ============================================================
  // PRESCRIBED DATE
  // ============================================================

  String _getPrescribedDate(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final dynamic value =
        data['prescribedAt'] ??
        data['prescribedDate'] ??
        data['date'] ??
        data['startDate'] ??
        data['orderedAt'] ??
        data['createdAt'] ??
        prescription['createdAt'];

    return _formatDate(value);
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Date not available';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return 'Date not available';
    }

    final date =
        DateTime.tryParse(text);

    if (date == null) {
      return text;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // ROLE FORMAT
  // ============================================================

  String _formatRole(String role) {
    final text =
        role.trim();

    if (text.isEmpty) {
      return '';
    }

    return text
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where(
          (word) => word.isNotEmpty,
        )
        .map(
          (word) =>
              '${word[0].toUpperCase()}'
              '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  // ============================================================
  // SEARCH
  // ============================================================

  bool _matchesSearch(
    Map<String, dynamic> prescription,
  ) {
    final query =
        _searchText.toLowerCase().trim();

    if (query.isEmpty) {
      return true;
    }

    final data =
        _recordData(prescription);

    final searchableText = [
      _getMedicineName(prescription),
      _getGenericName(prescription),
      _getDose(prescription),
      _getFrequency(prescription),
      _getPrescribedBy(prescription),
      _getAuthorRole(prescription),
      _getRoute(prescription),
      _getDuration(prescription),
      _getQuantity(prescription),
      _getRefills(prescription),
      _stringValue(
        data['status'] ??
            data['prescriptionStatus'],
      ),
      _getEndReason(prescription),
    ]
        .whereType<String>()
        .join(' ')
        .toLowerCase();

    return searchableText.contains(query);
  }

  // ============================================================
  // FILTERED DATA
  // ============================================================

  List<Map<String, dynamic>>
      get _filteredPrescriptions {
    return _prescriptions
        .where(_matchesSearch)
        .toList();
  }

  List<Map<String, dynamic>>
      get _activePrescriptions {
    return _filteredPrescriptions
        .where(_isActive)
        .toList();
  }

  List<Map<String, dynamic>>
      get _endedPrescriptions {
    return _filteredPrescriptions
        .where(
          (prescription) =>
              !_isActive(prescription),
        )
        .toList();
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================

  void _openPrescriptionDetails(
    Map<String, dynamic> prescription,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicalRecordDetailScreen(
          type: 'prescription',
          record: prescription,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge({
    required bool active,
  }) {
    final backgroundColor = active
        ? Colors.green.withValues(
            alpha: 0.10,
          )
        : Colors.grey.withValues(
            alpha: 0.12,
          );

    final textColor = active
        ? Colors.green.shade700
        : Colors.grey.shade700;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Active' : 'Ended',
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: Appcolors.secondaryText,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color:
                  Appcolors.secondaryText,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color:
                  Appcolors.primaryText,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SMALL INFO ROW
  // ============================================================

  Widget _buildSmallInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color:
              Appcolors.secondaryText,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color:
                  Appcolors.secondaryText,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color:
                  Appcolors.primaryText,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRESCRIPTION CARD
  // ============================================================

  Widget _buildPrescriptionCard(
    Map<String, dynamic> prescription,
  ) {
    final active =
        _isActive(prescription);

    final medicine =
        _getMedicineName(prescription);

    final generic =
        _getGenericName(prescription);

    final dose =
        _getDose(prescription);

    final frequency =
        _getFrequency(prescription);

    final prescribedBy =
        _getPrescribedBy(prescription);

    final authorRole =
        _getAuthorRole(prescription);

    final route =
        _getRoute(prescription);

    final duration =
        _getDuration(prescription);

    final quantity =
        _getQuantity(prescription);

    final refills =
        _getRefills(prescription);

    final date =
        _getPrescribedDate(prescription);

    final endReason =
        _getEndReason(prescription);

    final endedDate =
        _getEndedDate(prescription);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
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
          onTap: () {
            _openPrescriptionDetails(
              prescription,
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                          BoxDecoration(
                        color: Appcolors
                            .primary
                            .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .medication_outlined,
                        color:
                            Appcolors.primary,
                        size: 26,
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
                            medicine,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color: Appcolors
                                  .primaryText,
                            ),
                          ),
                          if (generic !=
                              null) ...[
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Generic: $generic',
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color: Appcolors
                                    .secondaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    _buildStatusBadge(
                      active: active,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                // ------------------------------------------------
                // MEDICATION DETAILS
                // ------------------------------------------------

                _buildDetailRow(
                  icon: Icons
                      .medication_outlined,
                  label: 'Dose',
                  value: dose,
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildDetailRow(
                  icon: Icons.repeat,
                  label: 'Frequency',
                  value: frequency,
                ),

                if (route != null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  _buildDetailRow(
                    icon:
                        Icons.alt_route,
                    label: 'Route',
                    value: route,
                  ),
                ],

                if (duration != null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  _buildDetailRow(
                    icon: Icons
                        .timer_outlined,
                    label: 'Duration',
                    value: duration,
                  ),
                ],

                if (quantity != null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  _buildDetailRow(
                    icon: Icons
                        .inventory_2_outlined,
                    label: 'Quantity',
                    value: quantity,
                  ),
                ],

                if (refills != null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  _buildDetailRow(
                    icon: Icons
                        .refresh_outlined,
                    label: 'Refills',
                    value: refills,
                  ),
                ],

                const SizedBox(
                  height: 14,
                ),

                const Divider(
                  height: 1,
                  color: Appcolors.border,
                ),

                const SizedBox(
                  height: 14,
                ),

                // ------------------------------------------------
                // PRESCRIBED BY
                // ------------------------------------------------

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Icon(
                      Icons
                          .person_outline,
                      size: 18,
                      color: Appcolors
                          .secondaryText,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Prescribed by',
                            style:
                                TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .w500,
                              color: Appcolors
                                  .secondaryText,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            prescribedBy,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color: Appcolors
                                  .primaryText,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                          if (authorRole !=
                              null) ...[
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              _formatRole(
                                authorRole,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color: Appcolors
                                    .secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                // ------------------------------------------------
                // PRESCRIBED DATE
                // ------------------------------------------------

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Icon(
                      Icons
                          .calendar_today_outlined,
                      size: 17,
                      color: Appcolors
                          .secondaryText,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        date,
                        style:
                            const TextStyle(
                          color: Appcolors
                              .secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                // ------------------------------------------------
                // ENDED INFORMATION
                // ------------------------------------------------

                if (!active &&
                    (endReason != null ||
                        endedDate != null)) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  if (endedDate != null)
                    _buildSmallInfoRow(
                      icon: Icons
                          .event_busy_outlined,
                      label: 'Ended',
                      value: endedDate,
                    ),
                  if (endReason != null) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    _buildSmallInfoRow(
                      icon: Icons
                          .info_outline,
                      label: 'Reason',
                      value: endReason,
                    ),
                  ],
                ],

                const SizedBox(
                  height: 12,
                ),

                // ------------------------------------------------
                // VIEW DETAILS
                // ------------------------------------------------

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    const Text(
                      'View details',
                      style: TextStyle(
                        color:
                            Appcolors.primary,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    const Icon(
                      Icons
                          .arrow_forward_ios,
                      size: 12,
                      color:
                          Appcolors.primary,
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

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required bool active,
  }) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        2,
        8,
        2,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? Colors.green
                  : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  Appcolors.primaryText,
            ),
          ),
          const SizedBox(
            width: 7,
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 3,
            ),
            decoration:
                BoxDecoration(
              color: Appcolors.primary
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color:
                    Appcolors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Appcolors.primary
                  .withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  Appcolors.primary,
              size: 30,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  Appcolors.primaryText,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  Appcolors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(
                color: Colors.red
                    .withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color:
                    Colors.red.shade600,
                size: 32,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Unable to load prescriptions',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
                color:
                    Appcolors.primaryText,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _error ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Appcolors.secondaryText,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            ElevatedButton.icon(
              onPressed:
                  _loadPrescriptions,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Try again',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Appcolors.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller:
          _searchController,
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
      textInputAction:
          TextInputAction.search,
      decoration:
          InputDecoration(
        hintText:
            'Search medicines, doctors, dosage...',
        hintStyle:
            const TextStyle(
          fontSize: 13,
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
            _searchText.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController
                          .clear();

                      setState(() {
                        _searchText = '';
                      });
                    },
                    icon:
                        const Icon(
                      Icons.clear,
                    ),
                  )
                : null,
        filled: true,
        fillColor:
            Appcolors.surface,
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color:
                Appcolors.border,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color:
                Appcolors.border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color:
                Appcolors.primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final activePrescriptions =
        _activePrescriptions;

    final endedPrescriptions =
        _endedPrescriptions;

    final filteredPrescriptions =
        _filteredPrescriptions;

    return Scaffold(
      backgroundColor:
          Appcolors.background,
      appBar: AppBar(
        backgroundColor:
            Appcolors.background,
        foregroundColor:
            Appcolors.primaryText,
        elevation: 0,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Prescriptions',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 2,
            ),
            Text(
              'Your prescribed medicines',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w400,
                color:
                    Appcolors.secondaryText,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      Appcolors.primary,
                ),
              )
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    color:
                        Appcolors.primary,
                    onRefresh:
                        _loadPrescriptions,
                    child:
                        CustomScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ------------------------------------------------
                        // SEARCH
                        // ------------------------------------------------

                        SliverToBoxAdapter(
                          child:
                              Padding(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              16,
                              8,
                              16,
                              18,
                            ),
                            child:
                                _buildSearchField(),
                          ),
                        ),

                        // ------------------------------------------------
                        // NO RESULTS
                        // ------------------------------------------------

                        if (filteredPrescriptions
                            .isEmpty)
                          SliverFillRemaining(
                            hasScrollBody:
                                false,
                            child:
                                Padding(
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
                                16,
                                10,
                                16,
                                30,
                              ),
                              child:
                                  _buildEmptyState(
                                title:
                                    _searchText
                                            .trim()
                                            .isNotEmpty
                                        ? 'No prescriptions found'
                                        : 'No prescriptions yet',
                                message:
                                    _searchText
                                            .trim()
                                            .isNotEmpty
                                        ? 'Try a different medicine, doctor, or dosage.'
                                        : 'Your prescribed medicines will appear here.',
                                icon: Icons
                                    .medication_outlined,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              16,
                              0,
                              16,
                              30,
                            ),
                            sliver:
                                SliverList(
                              delegate:
                                  SliverChildListDelegate(
                                [
                                  // --------------------------------------
                                  // ACTIVE
                                  // --------------------------------------

                                  if (activePrescriptions
                                      .isNotEmpty) ...[
                                    _buildSectionHeader(
                                      title:
                                          'Active prescriptions',
                                      count:
                                          activePrescriptions
                                              .length,
                                      active:
                                          true,
                                    ),
                                    ...activePrescriptions
                                        .map(
                                      _buildPrescriptionCard,
                                    ),
                                  ],

                                  // --------------------------------------
                                  // ENDED
                                  // --------------------------------------

                                  if (endedPrescriptions
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    _buildSectionHeader(
                                      title:
                                          'Ended prescriptions',
                                      count:
                                          endedPrescriptions
                                              .length,
                                      active:
                                          false,
                                    ),
                                    ...endedPrescriptions
                                        .map(
                                      _buildPrescriptionCard,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}