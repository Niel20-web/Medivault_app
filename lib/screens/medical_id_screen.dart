import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/appcolors.dart';
import '../services/patient_service.dart';

class MedicalIdScreen extends StatefulWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  final PatientService _patientService = PatientService();

  // Keeps the same QR while the app session is alive.
  static String? _cachedQrPayloadUrl;

  Map<String, dynamic>? _patient;

  String? _qrPayloadUrl;

  bool _isLoading = true;
  bool _isRegeneratingQr = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _patientService.getMyPatientProfile();

      final patientData = response['data'];

      if (patientData == null) {
        throw Exception(
          'Patient profile data not found.',
        );
      }

      final patient =
          Map<String, dynamic>.from(patientData);

      // Database UUID used by the Medical Profile QR endpoint.
      final patientUuid =
          patient['_id']?.toString();

      if (patientUuid == null || patientUuid.isEmpty) {
        throw Exception(
          'Patient record ID not found.',
        );
      }

      print(
        'MEDICAL ID PATIENT UUID: $patientUuid',
      );

      print(
        'MEDICAL ID PATIENT ID: ${patient['patientId']}',
      );

      String? payloadUrl = _cachedQrPayloadUrl;

      // Only generate a new QR if we don't already have one.
      if (payloadUrl == null || payloadUrl.isEmpty) {
        payloadUrl =
            await _generateQr(patientUuid);
      } else {
        print(
          'USING EXISTING MEDICAL QR: $payloadUrl',
        );
      }

      if (!mounted) return;

      setState(() {
        _patient = patient;
        _qrPayloadUrl = payloadUrl;
        _isLoading = false;
      });
    } catch (e) {
      print('MEDICAL ID ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<String> _generateQr(
    String patientUuid,
  ) async {
    final qrResponse =
        await _patientService.generateMedicalQr(
      patientUuid,
    );

    print(
      'GENERATED QR RESPONSE: $qrResponse',
    );

    // Backend response structure:
    //
    // {
    //   "success": true,
    //   "data": {
    //     "payloadUrl": "https://..."
    //   }
    // }
    final qrData = qrResponse['data'];

    if (qrData == null) {
      throw Exception(
        'QR data was not returned.',
      );
    }

    final payloadUrl =
        qrData['payloadUrl']?.toString();

    if (payloadUrl == null || payloadUrl.isEmpty) {
      throw Exception(
        'QR verification URL was not generated.',
      );
    }

    // Cache it so we don't regenerate every time
    // the Medical ID screen is opened.
    _cachedQrPayloadUrl = payloadUrl;

    print(
      'MEDICAL QR URL: $payloadUrl',
    );

    return payloadUrl;
  }

  Future<void> _regenerateQr() async {
    if (_patient == null) return;

    final patientUuid =
        _patient!['_id']?.toString();

    if (patientUuid == null ||
        patientUuid.isEmpty) {
      return;
    }

    final shouldRegenerate =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Regenerate QR code?',
          ),
          content: const Text(
            'This will invalidate the current QR code and create a new secure verification link.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Appcolors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Regenerate',
              ),
            ),
          ],
        );
      },
    );

    if (shouldRegenerate != true) {
      return;
    }

    setState(() {
      _isRegeneratingQr = true;
      _error = null;
    });

    try {
      final payloadUrl =
          await _generateQr(patientUuid);

      if (!mounted) return;

      setState(() {
        _qrPayloadUrl = payloadUrl;
        _isRegeneratingQr = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medical ID QR regenerated successfully.',
          ),
        ),
      );
    } catch (e) {
      print(
        'QR REGENERATION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isRegeneratingQr = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  void _showQrDialog() {
    if (_qrPayloadUrl == null ||
        _qrPayloadUrl!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'Medical ID QR',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Scan to verify Medical ID',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color:
                          Colors.grey.shade200,
                    ),
                  ),
                  child: QrImageView(
                    data:
                        _qrPayloadUrl!,
                    version:
                        QrVersions.auto,
                    size: 200,
                    padding:
                        EdgeInsets.zero,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Scanning this QR code opens the secure MediVault verification page.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(
                      context,
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
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        _patient?['firstName']
                ?.toString() ??
            '';

    final lastName =
        _patient?['lastName']
                ?.toString() ??
            '';

    final patientName =
        '$firstName $lastName'.trim();

    final patientId =
        _patient?['patientId']
                ?.toString() ??
            'Unavailable';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Medical ID',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
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
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(24),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .error_outline,
                          size: 52,
                          color:
                              Colors.redAccent,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Text(
                          _error!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            color:
                                Colors.black87,
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        ElevatedButton(
                          onPressed:
                              _loadPatientProfile,
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
                )
              : RefreshIndicator(
                  onRefresh:
                      _loadPatientProfile,
                  color:
                      Appcolors.primary,
                  child:
                      SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets
                            .all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'Your Medical ID',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Use your Medical ID QR code to securely share your verified MediVault record.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors
                                .grey
                                .shade600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(20),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              24,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withOpacity(
                                  0.05,
                                ),
                                blurRadius:
                                    20,
                                offset:
                                    const Offset(
                                  0,
                                  8,
                                ),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration:
                                    BoxDecoration(
                                  color: Appcolors
                                      .primary
                                      .withOpacity(
                                    0.1,
                                  ),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .medical_information_outlined,
                                  color:
                                      Appcolors
                                          .primary,
                                  size: 38,
                                ),
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              Text(
                                patientName
                                        .isEmpty
                                    ? 'MediVault Patient'
                                    : patientName,
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                'Patient ID: $patientId',
                                textAlign:
                                    TextAlign
                                        .center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),

                              const SizedBox(
                                height: 24,
                              ),

                              Container(
                                width:
                                    double.infinity,
                                padding:
                                    const EdgeInsets
                                        .all(18),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .grey
                                      .shade50,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                  border:
                                      Border.all(
                                    color: Colors
                                        .grey
                                        .shade200,
                                  ),
                                ),
                                child:
                                    Column(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        10,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            Colors
                                                .white,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                      child:
                                          QrImageView(
                                        data:
                                            _qrPayloadUrl!,
                                        version:
                                            QrVersions
                                                .auto,
                                        size:
                                            105,
                                        padding:
                                            EdgeInsets
                                                .zero,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 14,
                                    ),

                                    Text(
                                      'Scan to verify',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            14,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        color: Colors
                                            .grey
                                            .shade800,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      'Secure MediVault verification',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            12,
                                        color: Colors
                                            .grey
                                            .shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      _showQrDialog,
                                  icon:
                                      const Icon(
                                    Icons
                                        .qr_code_2,
                                  ),
                                  label:
                                      const Text(
                                    'View QR Code',
                                  ),
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        Appcolors
                                            .primary,
                                    foregroundColor:
                                        Colors
                                            .white,
                                    elevation:
                                        0,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical:
                                          15,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    OutlinedButton
                                        .icon(
                                  onPressed:
                                      _isRegeneratingQr
                                          ? null
                                          : _regenerateQr,
                                  icon:
                                      _isRegeneratingQr
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .refresh,
                                            ),
                                  label:
                                      Text(
                                    _isRegeneratingQr
                                        ? 'Regenerating...'
                                        : 'Regenerate QR',
                                  ),
                                  style:
                                      OutlinedButton
                                          .styleFrom(
                                    foregroundColor:
                                        Appcolors
                                            .primary,
                                    side:
                                        const BorderSide(
                                      color:
                                          Appcolors
                                              .primary,
                                    ),
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical:
                                          14,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(18),
                          decoration:
                              BoxDecoration(
                            color: Appcolors
                                .primary
                                .withOpacity(
                              0.06,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                            border:
                                Border.all(
                              color: Appcolors
                                  .primary
                                  .withOpacity(
                                0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration:
                                    BoxDecoration(
                                  color: Appcolors
                                      .primary
                                      .withOpacity(
                                    0.1,
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
                                      .verified_user_outlined,
                                  color:
                                      Appcolors
                                          .primary,
                                  size: 22,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Secure verification',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        fontSize:
                                            14,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      'Your QR code uses a secure verification link. Scanning it opens the MediVault public verification page instead of exposing your patient ID directly.',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            12,
                                        color: Colors
                                            .grey
                                            .shade600,
                                        height:
                                            1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}