import 'package:flutter/material.dart';

import '../utils/appcolors.dart';
import '../services/patient_service.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() =>
      _PrescriptionsPageState();
}

class _PrescriptionsPageState
    extends State<PrescriptionsPage> {
  final TextEditingController searchController =
      TextEditingController();

  final PatientService _patientService =
      PatientService();

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
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRESCRIPTIONS
  // ============================================================

  Future<void> _loadPrescriptions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final patientResponse =
          await _patientService.getMyPatientProfile();

      final patientData =
          patientResponse['data'];

      if (patientData == null ||
          patientData is! Map) {
        throw Exception(
          'Patient data was not returned by the server.',
        );
      }

      final patientId =
          patientData['_id'];

      if (patientId == null ||
          patientId.toString().trim().isEmpty) {
        throw Exception(
          'Patient ID was not returned by the server.',
        );
      }

      final historyResponse =
          await _patientService.getMedicalHistory(
        patientId.toString(),
      );

      final dynamic rawHistoryData =
          historyResponse['data'];

      final Map<String, dynamic> historyData =
          rawHistoryData is Map
              ? Map<String, dynamic>.from(
                  rawHistoryData,
                )
              : historyResponse;

      final dynamic rawPrescriptions =
          historyData['prescriptions'];

      if (!mounted) return;

      setState(() {
        if (rawPrescriptions is List) {
          _prescriptions = rawPrescriptions
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(item),
              )
              .toList();
        } else {
          _prescriptions = [];
        }

        _isLoading = false;
        _error = null;
      });

      print(
        'PRESCRIPTIONS LOADED: '
        '${_prescriptions.length}',
      );
    } catch (e) {
      print(
        'PRESCRIPTIONS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
        _prescriptions = [];
      });
    }
  }

  // ============================================================
  // UNWRAP RECORD DATA
  // ============================================================

  Map<String, dynamic> _recordData(
    Map<String, dynamic> record,
  ) {
    final dynamic nestedData =
        record['data'];

    if (nestedData is Map) {
      return Map<String, dynamic>.from(
        nestedData,
      );
    }

    return record;
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  String? _stringValue(
    dynamic value,
  ) {
    if (value == null) {
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

  // ============================================================
  // ACTIVE STATUS
  // ============================================================

  bool _isActive(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final value =
        data['isActive'];

    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() ==
          'true';
    }

    // If the backend doesn't provide
    // isActive, treat it as active rather
    // than hiding the prescription.
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

    final value =
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
          Map<String, dynamic>.from(
        value,
      );

      final nestedName =
          nested['name'] ??
          nested['medicationName'] ??
          nested['medicineName'] ??
          nested['drugName'] ??
          nested['displayName'];

      return _stringValue(
            nestedName,
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

    return _stringValue(
      data['genericName'],
    );
  }

  // ============================================================
  // DOSE
  // ============================================================

  String _getDose(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final value =
        data['dosage'] ??
        data['dose'] ??
        data['dosageInstruction'] ??
        data['doseInstruction'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(
        value,
      );

      return _stringValue(
            nested['value'] ??
                nested['text'] ??
                nested['amount'] ??
                nested['dose'],
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

    final value =
        data['frequency'] ??
        data['frequencyText'] ??
        data['schedule'] ??
        data['frequencyInstruction'];

    if (value is Map) {
      final nested =
          Map<String, dynamic>.from(
        value,
      );

      return _stringValue(
            nested['text'] ??
                nested['value'] ??
                nested['frequency'],
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

    return _stringValue(
      data['route'],
    );
  }

  // ============================================================
  // DURATION
  // ============================================================

  String? _getDuration(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    return _stringValue(
      data['duration'],
    );
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  String? _getQuantity(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    return _stringValue(
      data['quantity'],
    );
  }

  // ============================================================
  // REFILLS
  // ============================================================

  String? _getRefills(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final value =
        data['refills'];

    if (value == null) {
      return null;
    }

    return value.toString();
  }

  // ============================================================
  // PRESCRIBED BY
  // ============================================================

  String _getPrescribedBy(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final authorName =
        _stringValue(
      prescription['authorName'],
    );

    if (authorName != null) {
      return authorName;
    }

    final doctor =
        data['doctor'] ??
        data['doctorName'] ??
        data['prescribedBy'] ??
        data['provider'] ??
        data['prescriber'] ??
        data['physician'];

    if (doctor is Map) {
      final doctorMap =
          Map<String, dynamic>.from(
        doctor,
      );

      final name =
          doctorMap['name'] ??
          doctorMap['fullName'] ??
          doctorMap['displayName'] ??
          doctorMap['doctorName'];

      final nameValue =
          _stringValue(name);

      if (nameValue != null) {
        return nameValue;
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

    final directDoctor =
        _stringValue(doctor);

    if (directDoctor != null) {
      return directDoctor;
    }

    return 'Healthcare provider';
  }

  // ============================================================
  // AUTHOR ROLE
  // ============================================================

  String? _getAuthorRole(
    Map<String, dynamic> prescription,
  ) {
    return _stringValue(
      prescription['authorRole'],
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
      data['endReason'],
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

    final value =
        data['endedAt'] ??
        data['expiresAt'];

    if (value == null) {
      return null;
    }

    return _formatDate(
      value.toString(),
    );
  }

  // ============================================================
  // PRESCRIBED DATE
  // ============================================================

  String _getDate(
    Map<String, dynamic> prescription,
  ) {
    final data =
        _recordData(prescription);

    final date =
        data['prescribedAt'] ??
        data['prescribedDate'] ??
        data['date'] ??
        data['startDate'] ??
        prescription['createdAt'];

    if (date == null) {
      return 'Date not specified';
    }

    return _formatDate(
      date.toString(),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    String value,
  ) {
    try {
      final date =
          DateTime.parse(value);

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
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // FORMAT ROLE
  // ============================================================

  String _formatRole(
    String role,
  ) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Administrator';

      case 'DOCTOR':
        return 'Doctor';

      case 'NURSE':
        return 'Nurse';

      case 'ADMIN':
        return 'Administrator';

      default:
        return role
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (word) {
                if (word.isEmpty) {
                  return word;
                }

                return word[0].toUpperCase() +
                    word.substring(1);
              },
            )
            .join(' ');
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<Map<String, dynamic>>
      get _filteredPrescriptions {
    if (_searchText.trim().isEmpty) {
      return _prescriptions;
    }

    final query =
        _searchText.trim().toLowerCase();

    return _prescriptions.where(
      (prescription) {
        final medicine =
            _getMedicineName(
          prescription,
        );

        final generic =
            _getGenericName(
          prescription,
        );

        final dose =
            _getDose(prescription);

        final frequency =
            _getFrequency(
          prescription,
        );

        final prescribedBy =
            _getPrescribedBy(
          prescription,
        );

        final searchableText = [
          medicine,
          generic ?? '',
          dose,
          frequency,
          prescribedBy,
          _getRoute(prescription) ?? '',
          _getDuration(prescription) ?? '',
          _getQuantity(prescription) ?? '',
        ].join(' ').toLowerCase();

        return searchableText.contains(
          query,
        );
      },
    ).toList();
  }

  // ============================================================
  // ACTIVE PRESCRIPTIONS
  // ============================================================

  List<Map<String, dynamic>>
      get _activePrescriptions {
    return _filteredPrescriptions
        .where(
          (prescription) =>
              _isActive(prescription),
        )
        .toList();
  }

  // ============================================================
  // ENDED PRESCRIPTIONS
  // ============================================================

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final active =
        _activePrescriptions;

    final ended =
        _endedPrescriptions;

    return Scaffold(
      backgroundColor:
          Appcolors.background,

      appBar: AppBar(
        backgroundColor:
            Appcolors.background,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color:
                Appcolors.primaryText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Prescriptions',
              style: TextStyle(
                color:
                    Appcolors.primaryText,
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Your prescribed medicines',
              style: TextStyle(
                color:
                    Appcolors.secondaryText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),

      body: _isLoading
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
                      SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),

                        // ------------------------------------------------
                        // SEARCH
                        // ------------------------------------------------

                        TextField(
                          controller:
                              searchController,
                          onChanged:
                              (value) {
                            setState(() {
                              _searchText =
                                  value;
                            });
                          },
                          decoration:
                              InputDecoration(
                            hintText:
                                'Search medicines...',
                            prefixIcon:
                                const Icon(
                              Icons.search,
                              color: Appcolors
                                  .secondaryText,
                            ),
                            filled: true,
                            fillColor:
                                Appcolors
                                    .surface,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide(
                                color:
                                    Appcolors
                                        .border,
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide(
                                color:
                                    Appcolors
                                        .border,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    Appcolors
                                        .primary,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // ------------------------------------------------
                        // ACTIVE
                        // ------------------------------------------------

                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Appcolors
                                .secondaryText,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        if (active.isEmpty)
                          _buildSectionEmptyState(
                            icon: Icons
                                .medication_outlined,
                            title:
                                'No active prescriptions',
                            message:
                                'You currently have no active prescriptions.',
                          )
                        else
                          ...active.map(
                            (
                              prescription,
                            ) =>
                                _buildPrescriptionCard(
                              prescription,
                            ),
                          ),

                        // ------------------------------------------------
                        // ENDED
                        // ------------------------------------------------

                        if (ended.isNotEmpty) ...[
                          const SizedBox(
                            height: 18,
                          ),

                          const Text(
                            'ENDED',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Appcolors
                                  .secondaryText,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          ...ended.map(
                            (
                              prescription,
                            ) =>
                                _buildPrescriptionCard(
                              prescription,
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ),
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
        _getMedicineName(
      prescription,
    );

    final generic =
        _getGenericName(
      prescription,
    );

    final dose =
        _getDose(prescription);

    final frequency =
        _getFrequency(
      prescription,
    );

    final prescribedBy =
        _getPrescribedBy(
      prescription,
    );

    final authorRole =
        _getAuthorRole(
      prescription,
    );

    final route =
        _getRoute(prescription);

    final duration =
        _getDuration(prescription);

    final quantity =
        _getQuantity(prescription);

    final refills =
        _getRefills(prescription);

    final date =
        _getDate(prescription);

    final endReason =
        _getEndReason(prescription);

    final endedDate =
        _getEndedDate(prescription);

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            Appcolors.surface,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              Appcolors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          // ----------------------------------------------------
          // MEDICINE
          // ----------------------------------------------------

          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
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
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .medication_outlined,
                  color: Appcolors
                      .primary,
                  size: 25,
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
                        fontSize: 17,
                        fontWeight:
                            FontWeight
                                .bold,
                        color: Appcolors
                            .primaryText,
                      ),
                    ),

                    if (generic != null) ...[
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

          // ----------------------------------------------------
          // DOSE
          // ----------------------------------------------------

          _buildDetailRow(
            icon: Icons
                .medication_outlined,
            label: 'Dose',
            value: dose,
          ),

          const SizedBox(
            height: 10,
          ),

          // ----------------------------------------------------
          // FREQUENCY
          // ----------------------------------------------------

          _buildDetailRow(
            icon:
                Icons.repeat,
            label: 'Frequency',
            value:
                frequency,
          ),

          // ----------------------------------------------------
          // ROUTE
          // ----------------------------------------------------

          if (route != null) ...[
            const SizedBox(
              height: 10,
            ),
            _buildDetailRow(
              icon:
                  Icons.alt_route,
              label: 'Route',
              value:
                  route,
            ),
          ],

          // ----------------------------------------------------
          // DURATION
          // ----------------------------------------------------

          if (duration != null) ...[
            const SizedBox(
              height: 10,
            ),
            _buildDetailRow(
              icon:
                  Icons.timer_outlined,
              label: 'Duration',
              value:
                  duration,
            ),
          ],

          // ----------------------------------------------------
          // QUANTITY
          // ----------------------------------------------------

          if (quantity != null) ...[
            const SizedBox(
              height: 10,
            ),
            _buildDetailRow(
              icon:
                  Icons.inventory_2_outlined,
              label: 'Quantity',
              value:
                  quantity,
            ),
          ],

          // ----------------------------------------------------
          // REFILLS
          // ----------------------------------------------------

          if (refills != null) ...[
            const SizedBox(
              height: 10,
            ),
            _buildDetailRow(
              icon:
                  Icons.refresh,
              label: 'Refills',
              value:
                  refills,
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          Divider(
            color:
                Appcolors.border,
          ),

          const SizedBox(
            height: 10,
          ),

          // ----------------------------------------------------
          // PRESCRIBED BY
          // ----------------------------------------------------

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

                    if (authorRole != null) ...[
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        _formatRole(
                          authorRole,
                        ),
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

          // ----------------------------------------------------
          // DATE
          // ----------------------------------------------------

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

          // ----------------------------------------------------
          // ENDED INFORMATION
          // ----------------------------------------------------

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
                height: 8,
              ),
              _buildSmallInfoRow(
                icon: Icons
                    .info_outline,
                label: 'Reason',
                value: endReason,
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge({
    required bool active,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? Appcolors.primary
                .withValues(
                alpha: 0.1,
              )
            : Appcolors.secondaryText
                .withValues(
                alpha: 0.1,
              ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        active ? 'ACTIVE' : 'ENDED',
        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
          letterSpacing: 0.6,
          color: active
              ? Appcolors.primary
              : Appcolors.secondaryText,
        ),
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
          CrossAxisAlignment
              .start,
      children: [
        Icon(
          icon,
          size: 18,
          color:
              Appcolors.primary,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          '$label: ',
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w600,
            color:
                Appcolors.primaryText,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              fontSize: 14,
              color:
                  Appcolors.secondaryText,
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
          CrossAxisAlignment
              .start,
      children: [
        Icon(
          icon,
          size: 16,
          color:
              Appcolors.secondaryText,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          '$label: ',
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
            color:
                Appcolors.secondaryText,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Appcolors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY SECTION
  // ============================================================

  Widget _buildSectionEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration:
          BoxDecoration(
        color:
            Appcolors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              Appcolors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color:
                Appcolors.secondaryText,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            title,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
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
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color:
                  Appcolors.error,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Unable to load prescriptions',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: Appcolors
                    .primaryText,
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
                color: Appcolors
                    .secondaryText,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ElevatedButton(
              onPressed:
                  _loadPrescriptions,
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Appcolors
                        .primary,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}